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
end
