require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'sequence_diagram')
require 'hpricot'
require 'cgi'
require 'mocha'

class SequenceDiagramIntegrationTest < Test::Unit::TestCase
  
  def test_valid_sequence_diagram_generated
    text = 'Alice->Bob: Authentication Request
            Bob-->Alice: Authentication Response'
    result = call_sequence_diagram_for(text, nil, nil)
    doc = Hpricot.parse(result)
    assert_match(Regexp.new(Regexp.escape("http://www.websequencediagrams.com/?img=") + "(\\w*)"), doc.search("img").attr('src'))
  end
  
  def test_should_show_error_message_in_caseof_invalid_syntax
    text = 'Alice->Bob: Authentication Request
            Bob'

    result = call_sequence_diagram_for(text, nil, nil)

    div_tag = Hpricot.parse(result).search("div")

    assert_equal("Line 2: Syntax error.", div_tag.text)
    assert_equal("color:red;", div_tag.attr("style"))
  end

  def test_should_show_multiple_error_message_in_caseof_invalid_syntax
    text = 'Alice
            Bob'

    result = call_sequence_diagram_for(text, nil, nil)
    div_tag = Hpricot.parse(result).search("div")

    assert_equal("Line 1: Syntax error.<br />Line 2: Syntax error.", div_tag.inner_html)
    assert_equal("color:red;", div_tag.attr("style"))
  end

  def test_should_show_error_message_when_error_raised
    Net::HTTP.stubs(:post_form).returns(TimeoutError.new("some error message"))

    text = 'Alice->Bob: Authentication Request
            Bob-->Alice: Authentication Response'
    result = call_sequence_diagram_for(text, nil, nil)
    div_tag = Hpricot.parse(result).search("div")

    assert_equal("Error while talking to http://www.websequencediagrams.com/<br />some error message", div_tag.inner_html)
    assert_equal("color:red;", div_tag.attr("style"))
  end

  def test_should_show_error_message_when_unsuccessful_response
    Net::HTTP.stubs(:post_form).returns(Net::HTTPNotFound.new(404, 4.0, "page not found"))

    text = 'Alice->Bob: Authentication Request
            Bob-->Alice: Authentication Response'
    result = call_sequence_diagram_for(text, nil, nil)
    div_tag = Hpricot.parse(result).search("div")

    assert_equal("Error while talking to http://www.websequencediagrams.com/<br />page not found", div_tag.inner_html)
    assert_equal("color:red;", div_tag.attr("style"))
  end

  def test_should_include_title_in_result
    text = 'Alice->Bob: Authentication Request
            Bob-->Alice: Authentication Response'
    result = call_sequence_diagram_for(text, "My first sequence diagram", nil)
    assert result.include?("<h3>My first sequence diagram</h3>")
  end

  def test_should_provide_style_to_diagram
    text = 'Alice->Bob: Authentication Request
            Bob-->Alice: Authentication Response'
    Net::HTTP.expects(:post_form).
      with(URI.parse('http://www.websequencediagrams.com/index.php'), 'style' => 'napkin', 'message' => text).
      returns(stub_everything('http response'))
    call_sequence_diagram_for(text, nil, 'napkin')
  end

  private
  def call_sequence_diagram_for(text, title, style)
    params = {'text' => text}
    params['title'] = title unless title.nil?
    params['style'] = style unless style.nil?
    SequenceDiagram.new(params, nil, nil).execute
  end

end