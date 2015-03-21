require 'cgi'

class SequenceDiagram

  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
  end
    
  def execute
    begin
      response = call_web_sequence_diagram(@parameters['text'])
    rescue Interrupt, StandardError => error
      return exception(error)
    end

    return bad_response(response) unless response.kind_of?(Net::HTTPSuccess)

    title + syntax_error(response.body) + img_tag(response.body)
  end
  
  def can_be_cached?
    false  # if appropriate, switch to true once you move your macro to production
  end

  private
  def call_web_sequence_diagram(text)
    style = @parameters['style'] || 'default'
    Timeout.timeout(10) do
      Net::HTTP.post_form(URI.parse('http://www.websequencediagrams.com/index.php'), 'style' => style, 'message' => text)
    end
  end

  def title
    @parameters['title'].nil? ? '' : %{<h3>#{@parameters['title']}</h3>}
  end

  def img_tag(result)
    result =~ /img: "(.+)"/
    img_url = "http://www.websequencediagrams.com/#{ $1 }"
    %{<img src="#{img_url}" />}
  end

  def syntax_error(result)
    result =~ /errors: \[(.+)\]/ ? %{<div style="color:red;">#{$1.gsub(",","<br />").gsub('"','')}</div>} : ''
  end

  def exception(error)
    %{<div style="color:red;">Error while talking to http://www.websequencediagrams.com/<br />#{error.message}}
  end

  def bad_response(response)
    %{<div style="color:red;">Error while talking to http://www.websequencediagrams.com/<br />#{response.message}}
  end

end

