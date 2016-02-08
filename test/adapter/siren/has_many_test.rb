require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class Siren
        class HasManyTest < Minitest::Test
          
          RELS_URI = 'http://rels.example.com'
          HREF_URI = 'http://example.com'

          def setup
            ActionController::Base.cache_store.clear
            @author = Author.new(id: 1, name: 'Steve K.')
            @author.posts = []
            @author.bio = nil
            @post = Post.new(id: 1, title: 'New Post', body: 'Body')
            @post_without_comments = Post.new(id: 2, title: 'Second Post', body: 'Second')
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @first_comment.author = nil
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
            @second_comment.author = nil
            @post.comments = [@first_comment, @second_comment]
            @post_without_comments.comments = []
            @first_comment.post = @post
            @second_comment.post = @post
            @post.author = @author
            @post_without_comments.author = nil
            @blog = Blog.new(id: 1, name: 'My Blog!!')
            @blog.writer = @author
            @blog.articles = [@post]
            @post.blog = @blog
            @post_without_comments.blog = nil
            @tag = Tag.new(id: 1, name: '#hash_tag')
            @post.tags = [@tag]
            @serializer = PostSerializer.new(@post)
            @adapter = ActiveModel::Serializer::Adapter::Siren.new(@serializer)

            @virtual_value = VirtualValue.new(id: 1)
          end

          def mock_request(query_parameters = {})
            @options = {}
            @options[:context] = Class.new {
               define_method(:rel) { RELS_URI }
               define_method(:href) { HREF_URI }
            }.new
          end

          def test_includes_comments_url
            expected  = { 
              class: [ 'comments', 'collection' ],
              rel: [ "#{RELS_URI}/comments", "hasMany" ],
              href: "#{HREF_URI}/posts/1/comments"
            }
              
            mock_request
            comments = @adapter.serializable_hash(@options)[:entities].select do |entity|
              entity[:class].include? 'comments'
            end
            assert_equal 1, comments.length
            assert_equal expected, comments.first
          end

          def test_includes_linked_comments
            @adapter = ActiveModel::Serializer::Adapter::Siren.new(@serializer, include: [:comments])
            # each comment ought to have an abbreviated
            # version of the full representation in this list
            # have another link rel: collection 
            expected = [{
              class: ["comments", "collection"],
                rel: ["#{RELS_URI}/comments", "hasMany"],
              href: "#{HREF_URI}/posts/1/comments",
              entities: [
                {
                  rel: ["#{RELS_URI}/comment"],
                  href: "#{HREF_URI}/comments/1",
                  class: ["comment"], 
                  properties: {
                    body: 'ZOMG A COMMENT'
                  },
                  actions: [], 
                  links: [{:rel=>["self"], :href=>"http://example.com/comments/1"}]
                }, 
                {
                  rel: ["#{RELS_URI}/comment"],
                  href: "#{HREF_URI}/comments/2",
                  class: ["comment"], 
                  properties: {
                    body: 'ZOMG ANOTHER COMMENT'
                  },
                  actions: [],
                  links: [{:rel=>["self"], :href=>"http://example.com/comments/2"}]
                }
              ]
            }]
            mock_request
            
            assert_equal(
              expected,
              @adapter.serializable_hash(@options)[:entities].select do |i|
                i[:class].include? 'comments'
              end
            )
          end

          def test_limit_fields_of_linked_comments
            @adapter = ActiveModel::Serializer::Adapter::Siren.new(@serializer, include: [:comments], fields: { comment: [:id] })
            expected = [{
              id: '1',
              type: 'comments',
              relationships: {
                post: { data: { type: 'posts', id: '1' } },
                author: { data: nil }
              }
            }, {
              id: '2',
              type: 'comments',
              relationships: {
                post: { data: { type: 'posts', id: '1' } },
                author: { data: nil }
              }
            }]
            assert_equal expected, @adapter.serializable_hash[:included]
          end

          def test_no_include_linked_if_comments_is_empty
            serializer = PostSerializer.new(@post_without_comments)
            adapter = ActiveModel::Serializer::Adapter::Siren.new(serializer)

            assert_nil adapter.serializable_hash[:linked]
          end

          def test_include_type_for_association_when_different_than_name
            serializer = BlogSerializer.new(@blog)
            adapter = ActiveModel::Serializer::Adapter::Siren.new(serializer)
            actual = adapter.serializable_hash[:data][:relationships][:articles]

            expected = {
              data: [{
                type: 'posts',
                id: '1'
              }]
            }
            assert_equal expected, actual
          end

          def test_has_many_with_no_serializer
            serializer = PostWithTagsSerializer.new(@post)
            adapter = ActiveModel::Serializer::Adapter::Siren.new(serializer)

            assert_equal({
              data: {
                id: '1',
                type: 'posts',
                relationships: {
                  tags: { data: [@tag.as_json] }
                }
              }
            }, adapter.serializable_hash)
          end

          def test_has_many_with_virtual_value
            serializer = VirtualValueSerializer.new(@virtual_value)
            adapter = ActiveModel::Serializer::Adapter::Siren.new(serializer)

            assert_equal({
              data: {
                id: '1',
                type: 'virtual_values',
                relationships: {
                  maker: { data: { id: 1 } },
                  reviews: { data: [{ id: 1 }, { id: 2 }] }
                }
              }
            }, adapter.serializable_hash)
          end
        end
      end
    end
  end
end
