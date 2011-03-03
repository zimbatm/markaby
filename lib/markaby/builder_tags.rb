module Markaby
  module BuilderTags
    (XHTMLTransitional.tags - [:head]).each do |k|
      class_eval <<-CODE, __FILE__, __LINE__
        def #{k}(*args, &block)
          html_tag(#{k.inspect}, *args, &block)
        end
      CODE
    end

    # Every HTML tag method goes through an html_tag call.  So, calling <tt>div</tt> is equivalent
    # to calling <tt>html_tag(:div)</tt>.  All HTML tags in Markaby's list are given generated wrappers
    # for this method.
    #
    # If the @auto_validation setting is on, this method will check for many common mistakes which
    # could lead to invalid XHTML.
    def html_tag(sym, *args, &block)
      if @auto_validation && @tagset.self_closing.include?(sym) && block
        raise InvalidXhtmlError, "the `#{sym}' element is self-closing, please remove the block"
      elsif args.empty? && !block
        CssProxy.new(self, @streams.last, sym)
      else
        tag!(sym, *args, &block)
      end
    end

    # Builds a head tag.  Adds a <tt>meta</tt> tag inside with Content-Type
    # set to <tt>text/html; charset=utf-8</tt>.
    def head(*args, &block)
      tag!(:head, *args) do
        if @output_meta_tag
          if @tagset == Markaby::HTML5
            tag!(:meta, "charset" => "utf-8")
          else
            tag!(:meta, "http-equiv" => "Content-Type", "content" => "text/html; charset=utf-8")
          end
        end
        instance_eval(&block)
      end
    end

    # Builds an html tag.  An XML 1.0 instruction and an XHTML 1.0 Transitional doctype
    # are prepended.  Also assumes <tt>:xmlns => "http://www.w3.org/1999/xhtml",
    # :lang => "en"</tt>.
    def xhtml_transitional(attrs = {}, &block)
      self.tagset = Markaby::XHTMLTransitional
      xhtml_html(attrs, &block)
    end

    # Builds an html tag with XHTML 1.0 Strict doctype instead.
    def xhtml_strict(attrs = {}, &block)
      self.tagset = Markaby::XHTMLStrict
      xhtml_html(attrs, &block)
    end

    # Builds an html tag with XHTML 1.0 Frameset doctype instead.
    def xhtml_frameset(attrs = {}, &block)
      self.tagset = Markaby::XHTMLFrameset
      xhtml_html(attrs, &block)
    end

    def html5(attrs = {}, &block)
      self.tagset = Markaby::HTML5
      declare!(:DOCTYPE, :html)
      root_attrs = @root_attributes.dup
      root_attrs.delete :xmlns
      root_attrs.delete :'xml:lang'
      tag!(:html, root_attrs.merge(attrs), &block)
    end

  private

    def xhtml_html(attrs = {}, &block)
      instruct! if @output_xml_instruction
      declare!(:DOCTYPE, :html, :PUBLIC, *tagset.doctype)
      tag!(:html, @root_attributes.merge(attrs), &block)
    end
  end
end
