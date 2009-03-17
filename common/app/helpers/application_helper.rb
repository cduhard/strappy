module ApplicationHelper

  # dirty ugly hack to get rcov to see this
  def html_attrs(lang = 'en-US'); {:xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, :lang => lang}
  end

  def http_equiv_attrs
    {'http-equiv' => 'Content-Type', :content => 'text/html;charset=UTF-8'}
  end

  # Outputs the corresponding flash message if any are set
  def flash_messages
    messages = []
    %w(notice warning error).each do |msg|
      messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
    end
    messages
  end

  def blackbird_tags
    if SiteConfig.blackbird || true == session[:blackbird]
      '<script type="text/javascript" charset="utf-8" src="/blackbird/blackbird.js"></script>
<link href="/blackbird/blackbird.css" media="screen" rel="stylesheet" type="text/css" />'
    else
      no_blackbird
    end rescue no_blackbird
  end

  def no_blackbird
    '<script type="text/javascript" charset="utf-8">var log = {toggle: function() {}, move: function() {}, resize: function() {}, clear: function() {}, debug: function() {}, info: function() {}, warn: function() {}, error: function() {}, profile: function() {} };</script>'
  end
  
  def yield_authenticity_token
    if protect_against_forgery?
        javascript_tag do
          "window._auth_token_name = '#{request_forgery_protection_token}';" +
          "window._auth_token = '#{form_authenticity_token}';"
        end
    end
  end
  
  def render_error_messages_for_base(*objects)
    messages = objects.compact.map { |o| o.errors.on(:base)}.flatten
    render :partial => '/shared/error_messages', :object => messages unless messages.compact.empty?
  end
  
  def labeled_form_for(*args, &block)
    options = args.extract_options!.merge(:builder => LabeledFormBuilder)
    form_for(*(args + [options]), &block)
  end
  
  def remote_labeled_form_for(*args, &block)
    options = args.extract_options!.merge(:builder => LabeledFormBuilder)
    remote_form_for(*(args + [options]), &block)
  end
  
  def ajax_dialog(text, path, *args)
    options = args.extract_options!
    link_to_function text, "Modalbox.show('#{path}', {title: '#{options[:title] || text}', width: #{options[:width] || 500}})", options.except(:title, :width)
  end
end
