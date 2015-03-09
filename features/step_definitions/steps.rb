
Given(/^Amazon\.co\.uk is open$/) do
  init_values = {
    :start_page => 'http://amazon.co.uk'
  }
  @x = GenericWebsite.new(init_values)
end

When(/^I on click Sign\-in$/) do
  @x.perform_action "click_signin_text"
end

When(/^enter valid user name password$/) do
  @x.perform_action "type_username", $USERNAME
  @x.perform_action "type_password", $PASSWORD
end

Then(/^I am logged in$/) do
  @x.perform_action "click_signin"
end

Given(/^when I search for "(.*?)"$/) do |arg1|
  @x.perform_action "type_search_query", arg1
  @x.perform_action "submit_search"
end

When(/^the search results are displayed$/) do
  @x.perform_action "inspect_product", {"locator" => {"id"=> "result_0"}}
end

Then(/^the first result has the word "(.*?)" in it$/) do |arg1|
  assert_includes @x.current_page[:dynamic_mapping]['result_0'].downcase, arg1, "#{arg1} is not included in the title of the first search result"
end

Given(/^I add "(.*?)" to my basket$/) do |arg1|
  if !@x.current_page[:dynamic_mapping]['result_0']
    step "when I search for \"#{arg1}\""
    step "the search results are displayed"
    step "the first result has the word \"#{arg1}\" in it"
  end
  @x.perform_action "click_product", {"root_search" => false}
  @product_price = @x.current_page[:elements]['price']
  @x.perform_action "click_add_to_basket"
end

When(/^I check my basket total$/) do
  @x.perform_action "click_basket"
end

Then(/^it should match the price of "(.*?)"$/) do |arg1|
  basket_price = @x.current_page[:elements]['cart'].split("\n")[0].split(" ")[-1]
  assert_equal @product_price, basket_price, "Expected: #{@product_price} - Actual: #{basket_price} - (CLEAN BASKET FIRST)"
end