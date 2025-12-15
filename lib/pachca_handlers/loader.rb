# frozen_string_literal: true

module PachcaHandlers
  module Loader
    class << self
      def load!(load_handlers: true, load_tools: true)
        load_engine!
        load_app_handlers! if load_handlers
        load_app_tools! if load_tools
      end

      def load_engine!
        require_all_rb!(File.expand_path('..', __dir__))
      end

      def load_app_handlers!
        root = project_root
        require_all_rb!(File.join(root, 'app', 'handlers'))
      end

      def load_app_tools!
        root = project_root
        require_all_rb!(File.join(root, 'app', 'tools'))
      end

      private

      def project_root
        File.expand_path('../..', __dir__)
      end

      def require_all_rb!(dir)
        pattern = File.join(dir, '**', '*.rb')
        files = Dir[pattern]
        files.reject! { |f| File.basename(f) == 'loader.rb' }
        files.each { |file| require file }
      end
    end
  end
end
