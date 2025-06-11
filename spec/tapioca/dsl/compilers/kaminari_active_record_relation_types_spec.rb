# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class KaminariActiveRecordRelationTypesSpec < ::DslSpec
        before do
          ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        end

        after do
          ::ActiveRecord::Base.connection.disconnect!
        end

        describe "Tapioca::Dsl::Compilers::KaminariActiveRecordRelationTypes" do
          sig { void }
          def before_setup
            require "active_record"
            require "kaminari/activerecord"
          end

          describe "gather_constants" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers constants for classes that exist" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end

            it "does not gather constants for abstract classes" do
              add_ruby_file("abstract_record.rb", <<~RUBY)
                class AbstractRecord < ActiveRecord::Base
                  self.abstract_class = true
                end
              RUBY

              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < AbstractRecord
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end

            it "does not gather constants for classes without tables" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              assert_empty(gathered_constants)
            end
          end

          describe "decorate" do
            it "generates RBI file with paginated relation types" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  class PaginatedPrivateAssociationRelation < PrivateAssociationRelation
                    include Kaminari::PageScopeMethods

                    sig { params(args: T.untyped).returns(PaginatedPrivateAssociationRelation) }
                    def order(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateAssociationRelation) }
                    def per(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateAssociationRelation) }
                    def where(*args); end
                  end

                  class PaginatedPrivateCollectionProxy < PrivateCollectionProxy
                    include Kaminari::PageScopeMethods

                    sig { params(args: T.untyped).returns(PaginatedPrivateCollectionProxy) }
                    def order(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateCollectionProxy) }
                    def per(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateCollectionProxy) }
                    def where(*args); end
                  end

                  class PaginatedPrivateRelation < PrivateRelation
                    include Kaminari::PageScopeMethods

                    sig { params(args: T.untyped).returns(PaginatedPrivateRelation) }
                    def order(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateRelation) }
                    def per(*args); end

                    sig { params(args: T.untyped).returns(PaginatedPrivateRelation) }
                    def where(*args); end
                  end

                  PaginatedRelationType = T.type_alias { T.any(::Post::PaginatedPrivateRelation, ::Post::PaginatedPrivateAssociationRelation, ::Post::PaginatedPrivateCollectionProxy) }
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for multiple models" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end

                    create_table :comments do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("comment.rb", <<~RUBY)
                class Comment < ActiveRecord::Base
                end
              RUBY

              post_rbi = rbi_for(:Post)
              comment_rbi = rbi_for(:Comment)

              assert_includes(post_rbi, "class PaginatedPrivateRelation < PrivateRelation")
              assert_includes(post_rbi, "PaginatedRelationType = T.type_alias")

              assert_includes(comment_rbi, "class PaginatedPrivateRelation < PrivateRelation")
              assert_includes(comment_rbi, "PaginatedRelationType = T.type_alias")
            end
          end
        end
      end
    end
  end
end
