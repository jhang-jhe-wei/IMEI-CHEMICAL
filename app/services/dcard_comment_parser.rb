class DcardCommentParser
  Capybara.default_max_wait_time = 1
  # Capybara.default_driver = :selenium_chrome
  Capybara.default_driver = :selenium_chrome_headless

  CACHE_FILE_PATH = "#{Rails.root}/app/services/dcard_post_urls.json"

  def initialize(search_text)
    @search_text = search_text
    @b = Capybara.current_session
  end

  def perform
    post_urls.each do |post_url|
      puts "爬取#{post_url}"
      ActiveRecord::Base.transaction do
        load_post_comments(post_url)
      end
    end
    File.delete(CACHE_FILE_PATH) if File.exist?(CACHE_FILE_PATH)
    Capybara.current_session.driver.quit
  end

  private
  def load_post_comments(post_url)
    @b.visit(post_url)
    return if @b.all("#comment").empty?
    data_keys = []
    category = @b.all("a[href='#{/https:\/\/www.dcard.tw(.*)\/p\/\d*/.match(post_url)[1]}']").first&.text
    number_of_comments = @b.all("#comment>div>div").first&.text&.scan(/\d/)&.join&.to_i
    @b.scroll_to(@b.find("#comment"))
    until data_keys.size >= number_of_comments
      puts "取得留言中，目前進度#{(data_keys.size.to_f/number_of_comments.to_f) * 100} %"
      sleep(1)
      @b.execute_script <<~Javascript
      document.querySelectorAll("#comment div[data-key^='subCommentToggle-'] button").forEach((btn)=>{
        if(btn.textContent != '隱藏留言'){
            btn.click()
        }
      })
      Javascript
      sleep(2)
      @b.all("#comment div[data-key^='comment-']").each do |div|
        unless data_keys.include? div["data-key"]
          data_keys << div["data-key"]
          data = div.all("span").map(&:text)
          data[1..-4].each do |comment|
            comment_data = {user_name: data[0], category: category, context: comment, posted_at: data[-1], source_url: post_url, source_type: "Dcard"}
            puts "寫入資料#{comment_data.to_s}"
            Comment.create!(comment_data)
          end
        end
      end
      # @b.scroll_to(@b.all("#comment div[data-key^='comment-']").last)
      @b.execute_script "window.scrollBy(0,1000)"
        end
    end

    def post_urls
      if File.exist? CACHE_FILE_PATH
        JSON.parse(File.open(CACHE_FILE_PATH).read)
      else
        search_post_urls(@search_text)
      end
    end

    def search_post_urls(search_text)
      @b.visit("https://www.dcard.tw/search/posts?query=#{search_text}&field=title")
        post_urls = []
      until @b.has_content?("沒有更多文章囉！")
        @b.scroll_to(@b.all('div[data-key^="post-"] a').last)
        sleep(1)
        @b.all('div[data-key^="post-"] a').each do |a|
          post_url = a[:href]
          puts "取得文章連結#{post_url}"
          if post_urls.include?(post_url)
            puts "此連結已被存入"
          else
            post_urls << post_url
          end
        end
      end
      File.open(CACHE_FILE_PATH, "a+") do |f|
        f.write(post_urls.to_json)
      end
      post_urls
    end
  end


  # DcardCommentParser.new("麥片").perform
