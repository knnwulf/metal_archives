require_relative '../test_helper'

require 'metal_archives/parsers/artist'

class ArtistParserTest < Test::Unit::TestCase
  def test_basic_attributes
    artist = MetalArchives::Parsers::Artist.parse_html(data_for('pathfinder.html'))

    assert_equal 'Pathfinder', artist[:name]
    assert_equal [], artist[:aliases]
    assert_equal ISO3166::Country['PL'], artist[:country]
    assert_equal 'Poznań', artist[:location]
    assert_equal Date.new(2006), artist[:date_formed]
    assert_equal [MetalArchives::Range.new(Date.new(2006), nil)], artist[:date_active]
    assert_equal :active, artist[:status]
    assert_equal ['Symphonic Power'], artist[:genres]
    assert_equal ['Fantasy', 'Battles', 'Glory', 'The Four Elements', 'Metal'].sort, artist[:lyrical_themes].sort
    assert_equal 'Pathfinder was founded by Arkadiusz Ruth and Karol Mania.', artist[:comment]
    assert !artist[:independent]
  end

  def test_multiple
    artist = MetalArchives::Parsers::Artist.parse_html(data_for('rhapsody_of_fire.html'))

    assert_equal ['Thundercross', 'Rhapsody'].sort, artist[:aliases].sort
  end

  def test_associations
    omit 'not implemented yet'
    artist = MetalArchives::Parsers::Artist.parse_html(data_for('pathfinder.html'))
    # label
  end
end
