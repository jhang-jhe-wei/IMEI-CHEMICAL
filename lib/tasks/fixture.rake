namespace :fixture do
  desc "Load Excel"
  task load_excel: :environment do
    xlsx = Roo::Spreadsheet.open("#{Rails.root}/fixture.xlsx").parse(header_search: [/項次/])
    xlsx.each do |row|
      recipe = Recipe.find_or_create_by!(name: row['配方對應 ID'])
      recipe.recipe_items.create!(name: row['原料名稱'],
                                  weight: row['重量 (g)'],
                                  price: row['價格']
                                 )
    end
  end
end
