require 'json'
require 'selenium-webdriver'

ELEMENTS_DEFINITION = File.join(File.dirname(__FILE__), 'elements_def.json')


# extend String class with a helper method to convert snake_case to CamelCase
class String
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

# this class will read the config json file and initialize the elements defined for a specific page
class PageDataFactory
  attr_accessor :user_data
  class << self
    def method_missing(name, *args)
      begin
        #verify if config json is present
        raise "File #{ELEMENTS_DEFINITION} is missing." if !File.file?(ELEMENTS_DEFINITION)
        # parse config json
        config_data = JSON.parse(File.read(ELEMENTS_DEFINITION))
        # convert from snake_case name to CamelCase to match the json file format
        page_name = name.to_s.camel_case
        raise "Config Json file does not contain details about a page called #{page_name}.Define it first" if !config_data.has_key?(page_name)
        # initialize static data defined for the page
        new config_data[page_name]
      rescue Exception => e
        raise e
      end  
      
    end
  private :new
  end
  def initialize data
    @user_data = data
  end
end

# this class will provide webdriver functionality for a generic website
class GenericWebsite
  attr_accessor :driver, :current_page, :element
  def initialize init_values=nil
    begin
      raise "No web url was given" if init_values.nil? or !init_values[:start_page]
      @current_page = {}
      @element = nil
      @current_page[:page_data] = PageDataFactory.home_page
      @current_page[:page_name] = "HomePage"
      @current_page[:dynamic_mapping] = {}
      @current_page[:elements] = {}
      @driver = Selenium::WebDriver.for :firefox
      @driver.navigate.to init_values[:start_page]      
    rescue Exception => e
      raise e  
    end
  end
  
  # perform a specific action on a user defined element
  def perform_action action_name, *args
    raise "No such action #{action_name} defined for current page" if !@current_page[:page_data].user_data['actions'].has_key?(action_name)
    # override locator from config file if needed
    if args[0].is_a?(Hash) and args[0].has_key?('locator')
      locator = args[0]['locator']
    else
      locator = @current_page[:page_data].user_data['actions'][action_name]['locator']
    end
    # search the entire dom or just under the current element
    if args[0].is_a?(Hash) and args[0].has_key?('root_search')
      dom = args[0]['root_search'].eql?(true) ? @driver : @element
    else
      dom = @driver
    end
    # perform the search
    @element = dom.find_element(locator)
    # json contains only a predefined set of instructions
    if action_name.include?('click')
      @element.click
    elsif action_name.include?('type')
      @element.send_keys args[0]
    elsif action_name.include?('submit')
      @element.submit
    elsif action_name.include?('inspect')
      @element
    else
      raise "Don't know how to perform this action"
    end
    # wait for a specific element or page to be present after the action
    wait_and_update @current_page[:page_data].user_data['actions'][action_name]['wait']
  end
  
  # close the browser
  def close
    @driver.close
  end
  
  
  private
  # wait for a page or element to be present and update page attributes
  def wait_and_update data 
    if data.has_key?('page')
      @current_page[:page_data] = eval("PageDataFactory.#{data['page']}")
      @current_page[:page_name] = data['page']
      wait_for { displayed?(@current_page[:page_data].user_data['unique_locator']) }
    elsif data.has_key?('element')
      element_to_wait = data['element']
      element_locator = @current_page[:page_data].user_data['elements'][element_to_wait]['locator']
      wait_for { displayed?(element_locator) }
    end
    # if config file defines elements of interest, get them
    get_elements
    # if mentioned in config, will map some dynamic elements such as search results
    map_dynamic_elements
  end
  
  def wait_for(seconds=5)
    Selenium::WebDriver::Wait.new(:timeout => seconds).until { yield }
  end
  
  def displayed?(locator)
    if locator.has_key?('title')
      @driver.title.eql?(locator['title'])
    else
      @driver.find_element(locator).displayed?
    end
    true
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
  end
  
  # if elements of interest are defined initialize the object with them
  def get_elements
    @current_page[:elements] = {}
    if @current_page[:page_data].user_data.has_key?('elements')
      @current_page[:page_data].user_data['elements'].each do |k, locator|
        @current_page[:elements][k] = @driver.find_element(locator).text
      end
    end 
  end
  
  # if the config file has defined dynamic elements to be mapped
  def map_dynamic_elements
    @current_page[:dynamic_mapping] = {}
    if @current_page[:page_data].user_data.has_key?('dynamic_elements')
      element = @driver.find_element(@current_page[:page_data].user_data['dynamic_elements']['parent_object'])
      key_attribute = @current_page[:page_data].user_data['dynamic_elements']['key']
      value_attribute = @current_page[:page_data].user_data['dynamic_elements']['value']
      element.find_elements(@current_page[:page_data].user_data['dynamic_elements']['children']).each do |li|
        @current_page[:dynamic_mapping][li.attribute(key_attribute)] = li.find_element(value_attribute).text
      end
    end
  end
  
end