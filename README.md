Webdriver sandbox
=================

What it is:

* playground

What it is not:

* finished and fully tested

Idea:

* Distinction between actions on a webpage and the code performing the actions
* PageObject/elements_def.json
- describes each page: possible actions and validations, elements of interest, mapping of dynamic values such as search results 
* PageObject/page_objects.rb
- implements the actions and validations, updates the page object with the elements of interest as specified in the json file
* why?
- tests can be written only by editing the json and not the code.

To run:
* AMAZON_USERNAME='your_username' AMAZON_PASSWORD='your_password' cucumber --profile html_report
 