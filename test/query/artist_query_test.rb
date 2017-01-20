require_relative '../test_helper'

##
# Query method testing
#
# If a test fails, please check the online results to make sure it's not
# the content itself that has changed.
#
class ArtistQueryTest < Test::Unit::TestCase
  def test_find
    artist = MetalArchives::Artist.find 60908

    assert_not_nil artist
    assert_instance_of MetalArchives::Artist, artist
    assert_equal 60908, artist.id
    assert_equal 'Alberto Rionda', artist.name
    assert_equal ISO3166::Country['ES'], artist.country

    artist = MetalArchives::Artist.find(999999)

    assert_instance_of MetalArchives::Artist, artist
  end

  def test_find!
    artist = MetalArchives::Artist.find! 60908

    assert_not_nil artist
    assert_instance_of MetalArchives::Artist, artist
    assert_equal 60908, artist.id
    assert_equal 'Alberto Rionda', artist.name
    assert_equal ISO3166::Country['ES'], artist.country

    assert_raise MetalArchives::Errors::InvalidIDError do
      MetalArchives::Artist.find! nil
    end

    assert_raise MetalArchives::Errors::InvalidIDError do
      MetalArchives::Artist.find! 0
    end

    assert_raise MetalArchives::Errors::APIError do
      MetalArchives::Artist.find!(-1)
    end
  end

  def test_find_by
    artist = MetalArchives::Artist.find_by :name => 'Alberto Rionda'

    assert_not_nil artist
    assert_instance_of MetalArchives::Artist, artist
    assert_equal 'Alberto Rionda', artist.name
    assert_equal 60908, artist.id
    assert_equal ISO3166::Country['ES'], artist.country


    artist = MetalArchives::Artist.find_by :name => 'SomeNonExistantName'

    assert_nil artist
  end

  def test_find_by!
    artist = MetalArchives::Artist.find_by! :name => 'Alberto Rionda'

    assert_instance_of MetalArchives::Artist, artist

    artist = MetalArchives::Artist.find_by! :name => 'SomeNonExistantName'

    assert_nil artist
  end

  def test_search
    assert_instance_of MetalArchives::Collection, MetalArchives::Artist.search('Alberto Rionda')
    assert_equal 1, MetalArchives::Artist.search('Alberto Rionda').count
    assert_equal 9, MetalArchives::Artist.search('Name').count
    assert_equal 0, MetalArchives::Artist.search('SomeNonExistantName').count
    assert_equal 296, MetalArchives::Artist.search('Filip').count

    assert !MetalArchives::Artist.search('SomeNonExistantName').any?
  end

  def test_errors
    assert_nothing_raised do
      MetalArchives::Artist.new :id => nil
      MetalArchives::Artist.new :id => 0
      MetalArchives::Artist.new :id => -1
      MetalArchives::Artist.find_by :name => 'SomeNonExistantName'
      MetalArchives::Artist.search 'SomeNonExistantName'
    end

    assert_raise MetalArchives::Errors::InvalidIDError do
      MetalArchives::Artist.new(:id => nil).send :assemble
    end

    assert_raise MetalArchives::Errors::InvalidIDError do
      MetalArchives::Artist.new(:id => 0).send :assemble
    end

    assert_raise MetalArchives::Errors::APIError do
      MetalArchives::Artist.new(:id => -1).send :assemble
    end

    assert_nil MetalArchives::Artist.find_by :name => 'SomeNonExistantName'
    assert !MetalArchives::Artist.search('SomeNonExistantName').any?
  end
end
