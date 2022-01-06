class DcardCommentParser
  Capybara.default_max_wait_time = 1
  Capybara.default_driver = :selenium_chrome
  # Capybara.default_driver = :selenium_chrome_headless

  def initialize(search_text)
    @search_text = search_text
    @b = Capybara.current_session
  end

  def perform
    post_urls.each do |post_url|
      comments = get_post_comments(post_url)
      comments.each do |comment_id, data|
        comment_data = {user_name: data[0], context: data[1], posted_time: data[4], source_url: post_url, source_type: "Dcard"}
        puts(comment_data)
        Comment.create!(comment_data)
      end
    end
    Capybara.current_session.driver.quit
  end

  private

  def get_post_comments(post_url)
    @b.visit(post_url)
    return {} if @b.all("#comment").empty?
    comment_data = {}
    number_of_comments = @b.all("#comment>div>div").first&.text&.scan(/\d/)&.join&.to_i
    @b.scroll_to(@b.find("#comment"))
    until comment_data.size >= number_of_comments
      sleep(1)
      @b.execute_script <<~Javascript
      document.querySelectorAll("#comment div[data-key^='subCommentToggle-'] button").forEach((btn)=>{
        if(btn.textContent != '隱藏留言'){
            btn.click()
        }
      })
      Javascript
      sleep(1)
      @b.all("#comment div[data-key^='comment-']").map do |div|
        unless comment_data[div["data-key"]]
          comment_data[div["data-key"]] = div.all("span").map(&:text)
        end
      end
      @b.scroll_to(@b.all("#comment div[data-key^='comment-']").last)
      end
      comment_data
  end

  def post_urls
    unless @post_urls
      @b.visit("https://www.dcard.tw/search/posts?query=#{@search_text}&field=title")
        @post_urls = []
      until @b.has_content?("沒有更多文章囉！")
        @post_urls << @b.all('div[data-key^="post-"] a').map {|a| a[:href]}
        @b.scroll_to(@b.all('div[data-key^="post-"] a').last)
      end
      @post_urls.flatten!.uniq!
    end
    @post_urls
  end
end
