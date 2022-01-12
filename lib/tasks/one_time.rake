namespace :one_time do

  # bundle exec rake one_time:split_comment
  desc "Split comment by newline"
  task split_comment: :environment do # It should not run again
    Comment.where("context LIKE ?", "%\n%").each do |comment|
      comment.context.split("\n").each do |context|
        data = {context: context}.merge(comment.as_json.deep_symbolize_keys.except(:id, :context, :created_at, :updated_at))
        puts "寫入資料 #{data.to_s}"
        Comment.create!(data)
      end
    end
  end

  desc "Generate shops data"
  task generate_shops_data: :environment do
    shops = ["蝦皮", "樂天"]
    shops_fake_words = ["good", "nice", "very good", "讚喔", "還可以", "還 ok", "價格應該還好", "CP 值很高!", "東西好吃!", "真的很讚!"]

    Comment.where(source_type: shops).each do |comment|
      shops_fake_words.shuffle.each do |word|
        data = {context: word}.merge(comment.as_json.deep_symbolize_keys.except(:id, :context, :created_at, :updated_at))
        puts "寫入資料 #{data.to_s}"
        Comment.create!(data)
      end
    end
  end

  desc "Generate communities data"
  task generate_communities_data: :environment do
    communities = ["Dcard", "PTT"]
    source_urls = Comment.where(source_type: communities).pluck("comments.source_url")
    source_urls.shuffle.each do |source_url|
      break if Comment.where(source_type: communities).count >= 1000000
      comments = Comment.where(source_url: source_url)
      context_array = comments.pluck(:context)
      next if context_array.size > 100 || context_array.size <= 3
      comments.each do |comment|
        context_array.combination(3).to_a.shuffle.each do |ary|
          data = {context: ary.join}.merge(comment.as_json.deep_symbolize_keys.except(:id, :context, :created_at, :updated_at))
          puts "寫入資料 #{data.to_s}"
          Comment.create!(data)
        end
      end
    end
  end

  desc "Generate fake data"
  task generate_faker_data: :environment do
    recipe = Recipe.create!(name: "山藥黑豆", package_spec: "20g*10包*12袋/箱", remark: "含 5 %不良")
    recipe.recipe_items.create(name: "奶精", weight: 31.000, price: 400)
    recipe.recipe_items.create(name: "3+1豆粉", weight: 32.000, price: 200)
    recipe.recipe_items.create(name: "黑芝麻粉", weight: 4.000, price: 350)

    StockUnit.create!(code: "AA000010010", name: "燕麥粒", spec: "25kg/袋", format: "kg", quantity: 132.70)
    StockUnit.create!(code: "AA000010820", name: "大燕麥粒", spec: "25kg", format: "kg", quantity: 16092.63)
    StockUnit.create!(code: "AA000021050", name: "芭樂丁", spec: "3公斤(5臺斤)*6包/箱", format: "kg", quantity: 78.7)

    Order.create!(custom_code: "221010007", printed_at: Date.new(2021,12,01), name: "赤阪濃湯-玉米巧達", spec: "20g*10包*12袋/箱", quantity: 12, format: "袋", address: "新北市三重區三和路二段208號2樓之2")
    Order.create!(custom_code: "221010002", printed_at: Date.new(2021,12,01), name: "加鈣營養餅", spec: "30g*11包*10袋/箱", quantity: 10, format: "袋", address: "新北市新店區碧潭路55號 ")
    puts "Finished!"
  end
end
