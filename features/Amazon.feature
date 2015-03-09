Feature: Shop online at Amazon.co.uk


Background: Sign into Amazon.co.uk

Given Amazon.co.uk is open
When I on click Sign-in
And enter valid user name password
Then I am logged in


Scenario: Search for product add to basket

Given when I search for "chromecast"
When the search results are displayed
Then the first result has the word "chromecast" in it


Scenario: Check basket total

Given I add "chromecast" to my basket
When I check my basket total
Then it should match the price of "chromecast"