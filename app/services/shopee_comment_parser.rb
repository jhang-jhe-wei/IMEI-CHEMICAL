class ShopeeCommentParser

  CACHE_FILE_PATH = "#{Rails.root}/app/services/shopee_items.json"

  def initialize(search_text)
    @search_text = search_text
    @faraday = Faraday.new do |f|
      f.request :url_encoded
      f.response :json, {}
    end
  end

  def perform
    items.each do |item|
      puts "爬取#{item.to_s}"
      ActiveRecord::Base.transaction do
        load_item_comments(OpenStruct.new(item))
      end
    end
    File.delete(CACHE_FILE_PATH) if File.exist?(CACHE_FILE_PATH)
  end

  def load_item_comments(item)
    limit = 50
    offset = 0
    encoded_name = CGI.escape(item.name)
    loop do
      puts "取得#{item.name}的第#{offset}~#{offset+limit}筆評論"
      params = {
        filter: "1",
        flag: "1",
        itemid: item.item_id,
        limit: limit,
        offset: offset,
        shopid: item.shop_id,
        type: "0"
      }
      referer = "https://shopee.tw/#{encoded_name}-i.#{item.shop_id}.#{item.item_id}"
        headers = {
          "user-agent": Faker::Internet.user_agent(),
          "x-api-source": "pc",
          referer: referer
        }
      response = @faraday.get("https://shopee.tw/api/v2/item/get_ratings", params, headers)
      comments = response.body.dig("data", "ratings")&.map do |a|
        comment = {
          name: a.dig("product_items", 0, "name")&.gsub("\u0000", ''),
          price: item.price,
          context: a.dig("comment")&.gsub("\u0000", ''),
          category: a.dig("product_items", 0, "model_name")&.gsub("\u0000", ''),
          user_name: a.dig("author_username"),
          posted_at: Time.at(a.dig("ctime")),
          source_url: "https://shopee.tw/product/#{item.shop_id}/#{item.item_id}",
          source_type: "蝦皮"
        }
        Comment.create!(comment)
        comment
      end
      break unless comments.present?
      sleep(Random.rand())
      offset += limit
    end
  end

  def search_items(search_text)
    limit = 50
    newest = 0
    encoded_search_text = CGI.escape(search_text)
    items = []
    loop do
      puts "取得#{search_text}有關的第#{newest}~#{newest+limit}筆商品資訊"
      params = {
        by: "relevancy",
        keyword: encoded_search_text,
        limit: limit,
        newest: newest,
        order: "desc",
        page_type: "search",
        scenario: "PAGE_GLOBAL_SEARCH",
        version: "2",
      }
      headers = {
        "user-agent": Faker::Internet.user_agent(),
        "x-api-source": "pc",
        referer: "https://shopee.tw/search?keyword=#{encoded_search_text}"
      }
      response = @faraday.get("https://shopee.tw/api/v4/search/search_items", params, headers)
      data_set = response.body.dig("items")&.filter{|a| a.dig("adsid") == nil}&.map do |a|
        {
          item_id: a&.dig("item_basic", "itemid"),
          shop_id: a&.dig("item_basic", "shopid"),
          name: a&.dig("item_basic", "name"),
          ads_id: a&.dig("item_basic", "adsid"),
          price: a&.dig("item_basic", "price") / 100000,
        }
      end
      break unless data_set
      items << data_set
      puts data_set.map{|a| a.dig(:name)}.to_s
      newest += limit
    end
    items.flatten
  end

  def items
    if File.exist? CACHE_FILE_PATH
      JSON.parse(File.open(CACHE_FILE_PATH).read)
    else
      items = search_items(@search_text)
      File.open(CACHE_FILE_PATH, "a+") do |f|
        f.write(items.to_json)
      end
      items
    end
  end
end

# ShopeeCommentParser.new("麥片").perform
