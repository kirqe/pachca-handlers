# frozen_string_literal: true

module PachcaHandlers
  module Registry
    class ToolsRegistry
      @tools = {}

      def self.register(tool, name)
        @tools[name.to_sym] = tool
      end

      def self.get(name)
        @tools[name.to_sym]
      end

      def self.all
        @tools
      end
    end
  end
end
