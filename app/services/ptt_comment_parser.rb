class PttCommentParser
  def initialize(search_text)
    @faraday = Faraday.new() do |f|
      f.use FaradayMiddleware::FollowRedirects, limit: 5
    end
    @search_text = CGI.escape search_text
  end

  def perform
    load_board_lists.each do |board|
      # ["/bbs/Instant_Food"].each do |board|
      puts " 在看板 ##{board}"
      # board = "/cls/DMM_GAMES"
      articles_in_board(board) do |article|
        puts "  在文章 ##{article}"
        pushs = get_pushs_in_article(article)
        ActiveRecord::Base.transaction do
          pushs.each do |push|
            push.merge!({
              source_type: "PTT",
              source_url: "https://www.ptt.cc/#{article}",
            })
            puts "   寫入推文: #{push}"
            Comment.create! push
          end
        end
      end
    end
  end

  private
  # 取得看板分類
  def get_board_categories
    response = Faraday.get("https://www.pttweb.cc/cls/1")
    html = Nokogiri::HTML5(response.body)
    html.css(".e7-ul.e7-convenient a").map{|a| a.attributes["href"].value }.reject do |a|
      a.start_with? "/bbs"
    end
  end

  # 取得看板列表
  def get_board_lists
    get_board_categories.map do |board_category|
      response = Faraday.get("https://www.pttweb.cc#{board_category}")
      html = Nokogiri::HTML5(response.body)
      html.css(".e7-box a").map{|a| a.attributes["href"].value }
    end.flatten
  end

  # 讀取看板列表(快取)
  def load_board_lists
    JSON.parse(File.open("#{Rails.root}/app/services/ptt_board_list.json").read)
  end

  # 在指定看板搜尋麥片
  # https://www.ptt.cc#{board}/search?q=關鍵字
  def articles_in_board(board, page = 1, &block)
    puts "  articles_in_board(#{board}, #{page})"

      # 這一頁
      response = Faraday.get("https://www.ptt.cc#{board}/search?page=#{page}&q=#{@search_text}")
      html = Nokogiri::HTML5(response.body)
    articles = html.css(".title a").map{|a| a.attributes["href"].value }.each do |article|
      block&.call(article)
    end

    # 上一頁
    next_page_link = html.css(".action-bar .btn-group-paging a")[1]&.attributes&.dig("href")&.value
    if next_page_link.present?
      articles += articles_in_board(board, page + 1, &block)
    end
    return articles
  end

  def get_pushs_in_article(article)
    url = "https://www.ptt.cc#{article}"
    response = @faraday.get(url, {}, cookie: "over18=1;")
    html = Nokogiri::HTML5(response.body)
    html.css(".push").map do |push|
      {
        user_name: push.at_css(".push-userid").text.strip,
        context: push.at_css(".push-content").text[2..-1],
        posted_at: push.at_css(".push-ipdatetime").text.strip
      }
    end
  end
end
