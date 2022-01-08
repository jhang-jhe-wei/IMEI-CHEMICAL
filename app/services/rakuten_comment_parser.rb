class RakutenCommentParser

  CACHE_FILE_PATH = "#{Rails.root}/app/services/rakuten_item_data.json"

  def initialize(search_text)
    @search_text = search_text
  end

  def perform
    item_dataset.each do |data|
      puts "爬取#{data.to_s}"
      ActiveRecord::Base.transaction do
        load_item_comments(OpenStruct.new(data))
      end
    end
    File.delete(CACHE_FILE_PATH) if File.exist?(CACHE_FILE_PATH)
  end

  private
  def load_item_comments(data)
    review_page = 1
    loop do
      puts "取得 #{data.item_name} 的第 #{(review_page - 1) * 20 + 1} ~ #{review_page * 20} 筆評論"
      reviews = get_reviews(data, review_page)
      break if reviews.empty?
      reviews.each do |review|
        comment = {
          name: data.item_name,
          price: data.price,
          category: @search_text,
          context: review["review"],
          user_name: review["nickname"],
          posted_at: review["createdAt"],
          source_url: data.source_url,
          source_type: "樂天"
        }
        Comment.create!(comment)
        puts comment
      end
      review_page += 1
    end
  end

  def item_dataset
    if File.exist? CACHE_FILE_PATH
      JSON.parse(File.open(CACHE_FILE_PATH).read)
    else
      item_dataset = get_item_dataset(@search_text)
      File.open(CACHE_FILE_PATH, "a+") do |f|
        f.write(item_dataset.to_json)
      end
      item_dataset
    end
  end

  def get_item_dataset(search_text)
    encoded_search_text = CGI.escape(search_text)
    current_page = 1
    item_dataset = []
    loop do
      puts "查詢 #{search_text} 商品，目前第 #{current_page} 頁"
      res = Faraday.get("https://www.rakuten.com.tw/search/#{encoded_search_text}/?p=#{current_page}")
        html = Nokogiri::HTML5(res.body)
      data = JSON.parse(html.at_css('script[data-component-name="SearchPage"]').text)
      items = data.dig("initialData", "searchPage", "result", "items")
      item_data = items.map do |item|
        match = /https:\/\/www.rakuten.com.tw\/shop\/(.*)\/review\/(.*)\//.match(item.dig("review", "reviewUrl"))
        if match
          puts  "取得商品連結 #{item.dig("itemUrl")}"
          {
            shop_name: match[1],
            base_sku: match[2],
            shop_id: item.dig("shopId"),
            item_id: item.dig("itemId"),
            item_name: item.dig("itemName"),
            price: item.dig("itemPrice", "min"),
            source_url: item.dig("itemUrl"),
            source_type: "樂天"
          }
        else
          nil
        end
      end.compact
      break if item_data.empty?
      item_dataset << item_data
      current_page += 1
    end
    item_dataset.flatten
  end

  def get_reviews(data, page)
    res = Faraday.post('https://www.rakuten.com.tw/graphql') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        "operationName": "fetchItemReview",
        "variables": {
          "merchantId": get_merchant_id(data),
          "shopId": data.shop_id,
          "itemId": data.item_id,
          "hits": 20,
          "page": page
        },
        "query": "query fetchItemReview($merchantId: String!, $shopId: String!, $itemId: String!, $hits: Int, $page: Int) {  itemReviews(merchantId: $merchantId, shopId: $shopId, itemId: $itemId, hits: $hits, page: $page) {\n    reviewCount\n    reviews {\n      nickname\n      score\n      review\n      itemVariantValue\n      createdAt\n      __typename\n    }\n    scoreAverage\n    scoreCount {\n      one\n      two\n      three\n      four\n      five\n      __typename\n    }\n    page\n    __typename\n  }\n}\n"
      }.to_json
    end
    JSON.parse(res.body).dig("data", "itemReviews", "reviews")
  end

  def get_merchant_id(data)
    res = Faraday.post('https://www.rakuten.com.tw/graphql') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        "operationName": "fetchShopItem",
        "variables": {
          "baseSku": data.base_sku,
          "shopUrl": data.shop_name
        },
        "query": "query fetchShopItem($shopUrl: String!, $baseSku: String!) {\n  shopItem(shopUrl: $shopUrl, baseSku: $baseSku) {\n    baseSku\n    itemId\n    itemName\n    itemUrl\n    itemPrice {\n      max\n      min\n      __typename\n    }\n    itemImages {\n      alt\n      url\n      __typename\n    }\n    itemImageUrl\n    itemStatus\n    shopId\n    merchantId\n    shopName\n    shopUrl\n    variantMapping\n    isInventoryHidden\n    campaigns\n    isFreeShipping\n    isAdultProduct\n    point {\n      max\n      min\n      magnification\n      __typename\n    }\n    __typename\n  }\n}\n"
      }.to_json
    end

    json = JSON.parse(res.body)
    merchant_id = json.dig("data", "shopItem", "merchantId")
  end
end

# RakutenCommentParser.new("麥片").perform
