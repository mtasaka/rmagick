require 'rmagick'
require 'minitest/autorun'

class Image1_UT < Minitest::Test
  def setup
    @img = Magick::Image.new(20, 20)
  end

  def test_read_inline
    img = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    blob = img.to_blob
    encoded = [blob].pack('m*')
    res = Magick::Image.read_inline(encoded)
    assert_instance_of(Array, res)
    assert_instance_of(Magick::Image, res[0])
    expect(res[0]).to eq(img)
    expect { Magick::Image.read(nil) }.to raise_error(ArgumentError)
    expect { Magick::Image.read("") }.to raise_error(ArgumentError)
  end

  def test_spaceship
    img0 = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    img1 = Magick::Image.read(IMAGES_DIR + '/Button_1.gif').first
    sig0 = img0.signature
    sig1 = img1.signature
    # since <=> is based on the signature, the images should
    # have the same relationship to each other as their
    # signatures have to each other.
    expect(img0 <=> img1).to eq(sig0 <=> sig1)
    expect(img1 <=> img0).to eq(sig1 <=> sig0)
    expect(img0).to eq(img0)
    assert_not_equal(img0, img1)
    assert_nil(img0 <=> nil)
  end

  def test_adaptive_blur
    assert_nothing_raised do
      res = @img.adaptive_blur
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_blur(2) }
    assert_nothing_raised { @img.adaptive_blur(3, 2) }
    expect { @img.adaptive_blur(3, 2, 2) }.to raise_error(ArgumentError)
  end

  def test_adaptive_blur_channel
    assert_nothing_raised do
      res = @img.adaptive_blur_channel
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_blur_channel(2) }
    assert_nothing_raised { @img.adaptive_blur_channel(3, 2) }
    assert_nothing_raised { @img.adaptive_blur_channel(3, 2, Magick::RedChannel) }
    assert_nothing_raised { @img.adaptive_blur_channel(3, 2, Magick::RedChannel, Magick::BlueChannel) }
    expect { @img.adaptive_blur_channel(3, 2, 2) }.to raise_error(TypeError)
  end

  def test_adaptive_resize
    assert_nothing_raised do
      res = @img.adaptive_resize(10, 10)
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_resize(2) }
    expect { @img.adaptive_resize(-1.0) }.to raise_error(ArgumentError)
    expect { @img.adaptive_resize(10, 10, 10) }.to raise_error(ArgumentError)
    expect { @img.adaptive_resize }.to raise_error(ArgumentError)
    expect { @img.adaptive_resize(Float::MAX) }.to raise_error(RangeError)
  end

  def test_adaptive_sharpen
    assert_nothing_raised do
      res = @img.adaptive_sharpen
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_sharpen(2) }
    assert_nothing_raised { @img.adaptive_sharpen(3, 2) }
    expect { @img.adaptive_sharpen(3, 2, 2) }.to raise_error(ArgumentError)
  end

  def test_adaptive_sharpen_channel
    assert_nothing_raised do
      res = @img.adaptive_sharpen_channel
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_sharpen_channel(2) }
    assert_nothing_raised { @img.adaptive_sharpen_channel(3, 2) }
    assert_nothing_raised { @img.adaptive_sharpen_channel(3, 2, Magick::RedChannel) }
    assert_nothing_raised { @img.adaptive_sharpen_channel(3, 2, Magick::RedChannel, Magick::BlueChannel) }
    expect { @img.adaptive_sharpen_channel(3, 2, 2) }.to raise_error(TypeError)
  end

  def test_adaptive_threshold
    assert_nothing_raised do
      res = @img.adaptive_threshold
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.adaptive_threshold(2) }
    assert_nothing_raised { @img.adaptive_threshold(2, 4) }
    assert_nothing_raised { @img.adaptive_threshold(2, 4, 1) }
    expect { @img.adaptive_threshold(2, 4, 1, 2) }.to raise_error(ArgumentError)
  end

  def test_add_compose_mask
    mask = Magick::Image.new(20, 20)
    assert_nothing_raised { @img.add_compose_mask(mask) }
    assert_nothing_raised { @img.delete_compose_mask }
    assert_nothing_raised { @img.add_compose_mask(mask) }
    assert_nothing_raised { @img.add_compose_mask(mask) }
    assert_nothing_raised { @img.delete_compose_mask }
    assert_nothing_raised { @img.delete_compose_mask }

    mask = Magick::Image.new(10, 10)
    expect { @img.add_compose_mask(mask) }.to raise_error(ArgumentError)
  end

  def test_add_noise
    Magick::NoiseType.values do |noise|
      assert_nothing_raised { @img.add_noise(noise) }
    end
    expect { @img.add_noise(0) }.to raise_error(TypeError)
  end

  def test_add_noise_channel
    assert_nothing_raised { @img.add_noise_channel(Magick::UniformNoise) }
    assert_nothing_raised { @img.add_noise_channel(Magick::UniformNoise, Magick::RedChannel) }
    assert_nothing_raised { @img.add_noise_channel(Magick::GaussianNoise, Magick::BlueChannel) }
    assert_nothing_raised { @img.add_noise_channel(Magick::ImpulseNoise, Magick::GreenChannel) }
    assert_nothing_raised { @img.add_noise_channel(Magick::LaplacianNoise, Magick::RedChannel, Magick::GreenChannel) }
    assert_nothing_raised { @img.add_noise_channel(Magick::PoissonNoise, Magick::RedChannel, Magick::GreenChannel, Magick::BlueChannel) }

    # Not a NoiseType
    expect { @img.add_noise_channel(1) }.to raise_error(TypeError)
    # Not a ChannelType
    expect { @img.add_noise_channel(Magick::UniformNoise, Magick::RedChannel, 1) }.to raise_error(TypeError)
    # Too few arguments
    expect { @img.add_noise_channel }.to raise_error(ArgumentError)
  end

  def test_add_delete_profile
    img = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    assert_nothing_raised { img.add_profile(File.join(__dir__, 'cmyk.icm')) }
    # expect { img.add_profile(File.join(__dir__, 'srgb.icm')) }.to raise_error(Magick::ImageMagickError)

    img.each_profile { |name, _value| expect(name).to eq('icc') }
    assert_nothing_raised { img.delete_profile('icc') }
  end

  def test_affine_matrix
    affine = Magick::AffineMatrix.new(1, Math::PI / 6, Math::PI / 6, 1, 0, 0)
    assert_nothing_raised { @img.affine_transform(affine) }
    expect { @img.affine_transform(0) }.to raise_error(TypeError)
    res = @img.affine_transform(affine)
    assert_instance_of(Magick::Image,  res)
  end

  # test alpha backward compatibility. Image#alpha w/o arguments acts like alpha?
  def test_alpha_compat
    assert_nothing_raised { @img.alpha }
    assert !@img.alpha
    assert_nothing_raised { @img.alpha Magick::ActivateAlphaChannel }
    assert @img.alpha
  end

  def test_alpha
    assert_nothing_raised { @img.alpha? }
    assert !@img.alpha?
    assert_nothing_raised { @img.alpha Magick::ActivateAlphaChannel }
    assert @img.alpha?
    assert_nothing_raised { @img.alpha Magick::DeactivateAlphaChannel }
    assert !@img.alpha?
    assert_nothing_raised { @img.alpha Magick::OpaqueAlphaChannel }
    assert_nothing_raised { @img.alpha Magick::SetAlphaChannel }
    expect { @img.alpha Magick::SetAlphaChannel, Magick::OpaqueAlphaChannel }.to raise_error(ArgumentError)
    @img.freeze
    expect { @img.alpha Magick::SetAlphaChannel }.to raise_error(FreezeError)
  end

  def test_aref
    img = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    assert_nil(img[nil])
    assert_nil(img['label'])
    assert_match(/^Creator: PolyView/, img[:comment])
  end

  def test_aset
    @img['label'] = 'foobarbaz'
    @img[:comment] = 'Hello world'
    expect(@img['label']).to eq('foobarbaz')
    expect(@img['comment']).to eq('Hello world')
    assert_nothing_raised { @img[nil] = 'foobarbaz' }
  end

  def test_auto_gamma
    res = nil
    assert_nothing_raised { res = @img.auto_gamma_channel }
    assert_instance_of(Magick::Image, res)
    assert_not_same(@img, res)
    assert_nothing_raised { res = @img.auto_gamma_channel Magick::RedChannel }
    assert_nothing_raised { res = @img.auto_gamma_channel Magick::RedChannel, Magick::BlueChannel }
    expect { @img.auto_gamma_channel(1) }.to raise_error(TypeError)
  end

  def test_auto_level
    res = nil
    assert_nothing_raised { res = @img.auto_level_channel }
    assert_instance_of(Magick::Image, res)
    assert_not_same(@img, res)
    assert_nothing_raised { res = @img.auto_level_channel Magick::RedChannel }
    assert_nothing_raised { res = @img.auto_level_channel Magick::RedChannel, Magick::BlueChannel }
    expect { @img.auto_level_channel(1) }.to raise_error(TypeError)
  end

  def test_auto_orient
    Magick::OrientationType.values.each do |v|
      assert_nothing_raised do
        img = Magick::Image.new(10, 10)
        img.orientation = v
        res = img.auto_orient
        assert_instance_of(Magick::Image, res)
        assert_not_same(img, res)
      end
    end

    assert_nothing_raised do
      res = @img.auto_orient!
      # When not changed, returns nil
      assert_nil(res)
    end
  end

  def test_bilevel_channel
    expect { @img.bilevel_channel }.to raise_error(ArgumentError)
    assert_nothing_raised { @img.bilevel_channel(100) }
    assert_nothing_raised { @img.bilevel_channel(100, Magick::RedChannel) }
    assert_nothing_raised { @img.bilevel_channel(100, Magick::RedChannel, Magick::BlueChannel, Magick::GreenChannel, Magick::OpacityChannel) }
    assert_nothing_raised { @img.bilevel_channel(100, Magick::CyanChannel, Magick::MagentaChannel, Magick::YellowChannel, Magick::BlackChannel) }
    assert_nothing_raised { @img.bilevel_channel(100, Magick::GrayChannel) }
    assert_nothing_raised { @img.bilevel_channel(100, Magick::AllChannels) }
    expect { @img.bilevel_channel(100, 2) }.to raise_error(TypeError)
    res = @img.bilevel_channel(100)
    assert_instance_of(Magick::Image, res)
  end

  def test_blend
    @img2 = Magick::Image.new(20, 20) { self.background_color = 'black' }
    assert_nothing_raised { @img.blend(@img2, 0.25) }
    res = @img.blend(@img2, 0.25)

    Magick::GravityType.values do |gravity|
      assert_nothing_raised { @img.blend(@img2, 0.25, 0.75, gravity) }
      assert_nothing_raised { @img.blend(@img2, 0.25, 0.75, gravity, 10) }
      assert_nothing_raised { @img.blend(@img2, 0.25, 0.75, gravity, 10, 10) }
    end

    assert_instance_of(Magick::Image, res)
    assert_nothing_raised { @img.blend(@img2, '25%') }
    assert_nothing_raised { @img.blend(@img2, 0.25, 0.75) }
    assert_nothing_raised { @img.blend(@img2, '25%', '75%') }
    expect { @img.blend }.to raise_error(ArgumentError)
    expect { @img.blend(@img2, 'x') }.to raise_error(ArgumentError)
    expect { @img.blend(@img2, 0.25, []) }.to raise_error(TypeError)
    expect { @img.blend(@img2, 0.25, 0.75, 'x') }.to raise_error(TypeError)
    expect { @img.blend(@img2, 0.25, 0.75, Magick::CenterGravity, 'x') }.to raise_error(TypeError)
    expect { @img.blend(@img2, 0.25, 0.75, Magick::CenterGravity, 10, []) }.to raise_error(TypeError)

    @img2.destroy!
    expect { @img.blend(@img2, '25%') }.to raise_error(Magick::DestroyedImageError)
  end

  def test_blue_shift
    assert_not_same(@img, @img.blue_shift)
    assert_not_same(@img, @img.blue_shift(2.0))
    expect { @img.blue_shift('x') }.to raise_error(TypeError)
    expect { @img.blue_shift(2, 2) }.to raise_error(ArgumentError)
  end

  def test_blur_channel
    assert_nothing_raised { @img.blur_channel }
    assert_nothing_raised { @img.blur_channel(1) }
    assert_nothing_raised { @img.blur_channel(1, 2) }
    assert_nothing_raised { @img.blur_channel(1, 2, Magick::RedChannel) }
    assert_nothing_raised { @img.blur_channel(1, 2, Magick::RedChannel, Magick::BlueChannel, Magick::GreenChannel, Magick::OpacityChannel) }
    assert_nothing_raised { @img.blur_channel(1, 2, Magick::CyanChannel, Magick::MagentaChannel, Magick::YellowChannel, Magick::BlackChannel) }
    assert_nothing_raised { @img.blur_channel(1, 2, Magick::GrayChannel) }
    assert_nothing_raised { @img.blur_channel(1, 2, Magick::AllChannels) }
    expect { @img.blur_channel(1, 2, 2) }.to raise_error(TypeError)
    res = @img.blur_channel
    assert_instance_of(Magick::Image, res)
  end

  def test_blur_image
    assert_nothing_raised { @img.blur_image }
    assert_nothing_raised { @img.blur_image(1) }
    assert_nothing_raised { @img.blur_image(1, 2) }
    expect { @img.blur_image(1, 2, 3) }.to raise_error(ArgumentError)
    res = @img.blur_image
    assert_instance_of(Magick::Image, res)
  end

  def test_black_threshold
    expect { @img.black_threshold }.to raise_error(ArgumentError)
    assert_nothing_raised { @img.black_threshold(50) }
    assert_nothing_raised { @img.black_threshold(50, 50) }
    assert_nothing_raised { @img.black_threshold(50, 50, 50) }
    expect { @img.black_threshold(50, 50, 50, 50) }.to raise_error(ArgumentError)
    assert_nothing_raised { @img.black_threshold(50, 50, 50, alpha: 50) }
    expect { @img.black_threshold(50, 50, 50, wrong: 50) }.to raise_error(ArgumentError)
    expect { @img.black_threshold(50, 50, 50, alpha: 50, extra: 50) }.to raise_error(ArgumentError)
    expect { @img.black_threshold(50, 50, 50, 50, 50) }.to raise_error(ArgumentError)
    res = @img.black_threshold(50)
    assert_instance_of(Magick::Image, res)
  end

  def test_border
    assert_nothing_raised { @img.border(2, 2, 'red') }
    assert_nothing_raised { @img.border!(2, 2, 'red') }
    res = @img.border(2, 2, 'red')
    assert_instance_of(Magick::Image, res)
    @img.freeze
    expect { @img.border!(2, 2, 'red') }.to raise_error(FreezeError)
  end

  def test_capture
    # assert_nothing_raised { Magick::Image.capture }
    # assert_nothing_raised { Magick::Image.capture(true) }
    # assert_nothing_raised { Magick::Image.capture(true, true) }
    # assert_nothing_raised { Magick::Image.capture(true, true, true) }
    # assert_nothing_raised { Magick::Image.capture(true, true, true, true) }
    # assert_nothing_raised { Magick::Image.capture(true, true, true, true, true) }
    expect { Magick::Image.capture(true, true, true, true, true, true) }.to raise_error(ArgumentError)
  end

  def test_change_geometry
    expect { @img.change_geometry('sss') }.to raise_error(ArgumentError)
    expect { @img.change_geometry('100x100') }.to raise_error(LocalJumpError)
    assert_nothing_raised do
      res = @img.change_geometry('100x100') { 1 }
      expect(res).to eq(1)
    end
    expect { @img.change_geometry([]) }.to raise_error(ArgumentError)
  end

  def test_changed?
    #        assert_block { !@img.changed? }
    #        @img.pixel_color(0,0,'red')
    #        assert_block { @img.changed? }
  end

  def test_channel
    Magick::ChannelType.values do |channel|
      assert_nothing_raised { @img.channel(channel) }
    end

    assert_instance_of(Magick::Image, @img.channel(Magick::RedChannel))
    expect { @img.channel(2) }.to raise_error(TypeError)
  end

  def test_channel_depth
    assert_nothing_raised { @img.channel_depth }
    assert_nothing_raised { @img.channel_depth(Magick::RedChannel) }
    assert_nothing_raised { @img.channel_depth(Magick::RedChannel, Magick::BlueChannel) }
    assert_nothing_raised { @img.channel_depth(Magick::GreenChannel, Magick::OpacityChannel) }
    assert_nothing_raised { @img.channel_depth(Magick::MagentaChannel, Magick::CyanChannel) }
    assert_nothing_raised { @img.channel_depth(Magick::CyanChannel, Magick::BlackChannel) }
    assert_nothing_raised { @img.channel_depth(Magick::GrayChannel) }
    expect { @img.channel_depth(2) }.to raise_error(TypeError)
    assert_kind_of(Integer, @img.channel_depth(Magick::RedChannel))
  end

  def test_channel_extrema
    assert_nothing_raised do
      res = @img.channel_extrema
      assert_instance_of(Array, res)
      expect(res.length).to eq(2)
      assert_kind_of(Integer, res[0])
      assert_kind_of(Integer, res[1])
    end
    assert_nothing_raised { @img.channel_extrema(Magick::RedChannel) }
    assert_nothing_raised { @img.channel_extrema(Magick::RedChannel, Magick::BlueChannel) }
    assert_nothing_raised { @img.channel_extrema(Magick::GreenChannel, Magick::OpacityChannel) }
    assert_nothing_raised { @img.channel_extrema(Magick::MagentaChannel, Magick::CyanChannel) }
    assert_nothing_raised { @img.channel_extrema(Magick::CyanChannel, Magick::BlackChannel) }
    assert_nothing_raised { @img.channel_extrema(Magick::GrayChannel) }
    expect { @img.channel_extrema(2) }.to raise_error(TypeError)
  end

  def test_channel_mean
    assert_nothing_raised do
      res = @img.channel_mean
      assert_instance_of(Array, res)
      expect(res.length).to eq(2)
      assert_instance_of(Float, res[0])
      assert_instance_of(Float, res[1])
    end
    assert_nothing_raised { @img.channel_mean(Magick::RedChannel) }
    assert_nothing_raised { @img.channel_mean(Magick::RedChannel, Magick::BlueChannel) }
    assert_nothing_raised { @img.channel_mean(Magick::GreenChannel, Magick::OpacityChannel) }
    assert_nothing_raised { @img.channel_mean(Magick::MagentaChannel, Magick::CyanChannel) }
    assert_nothing_raised { @img.channel_mean(Magick::CyanChannel, Magick::BlackChannel) }
    assert_nothing_raised { @img.channel_mean(Magick::GrayChannel) }
    expect { @img.channel_mean(2) }.to raise_error(TypeError)
  end

  def test_charcoal
    assert_nothing_raised do
      res = @img.charcoal
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.charcoal(1.0) }
    assert_nothing_raised { @img.charcoal(1.0, 2.0) }
    expect { @img.charcoal(1.0, 2.0, 3.0) }.to raise_error(ArgumentError)
  end

  def test_chop
    assert_nothing_raised do
      res = @img.chop(10, 10, 10, 10)
      assert_instance_of(Magick::Image, res)
    end
  end

  def test_clone
    assert_nothing_raised do
      res = @img.clone
      assert_instance_of(Magick::Image, res)
      expect(@img).to eq(res)
    end
    res = @img.clone
    expect(@img.frozen?).to eq(res.frozen?)
    @img.freeze
    res = @img.clone
    expect(@img.frozen?).to eq(res.frozen?)
  end

  def test_clut_channel
    img = Magick::Image.new(20, 20) { self.colorspace = Magick::GRAYColorspace }
    clut = Magick::Image.new(20, 1) { self.background_color = 'red' }
    res = nil
    assert_nothing_raised { res = img.clut_channel(clut) }
    assert_same(res, img)
    assert_nothing_raised { img.clut_channel(clut, Magick::RedChannel) }
    assert_nothing_raised { img.clut_channel(clut, Magick::RedChannel, Magick::BlueChannel) }
    expect { img.clut_channel }.to raise_error(ArgumentError)
    expect { img.clut_channel(clut, 1, Magick::RedChannel) }.to raise_error(ArgumentError)
  end

  def test_color_fill_to_border
    expect { @img.color_fill_to_border(-1, 1, 'red') }.to raise_error(ArgumentError)
    expect { @img.color_fill_to_border(1, 100, 'red') }.to raise_error(ArgumentError)
    assert_nothing_raised do
      res = @img.color_fill_to_border(@img.columns / 2, @img.rows / 2, 'red')
      assert_instance_of(Magick::Image, res)
    end
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { @img.color_fill_to_border(@img.columns / 2, @img.rows / 2, pixel) }
  end

  def test_color_floodfill
    expect { @img.color_floodfill(-1, 1, 'red') }.to raise_error(ArgumentError)
    expect { @img.color_floodfill(1, 100, 'red') }.to raise_error(ArgumentError)
    assert_nothing_raised do
      res = @img.color_floodfill(@img.columns / 2, @img.rows / 2, 'red')
      assert_instance_of(Magick::Image, res)
    end
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { @img.color_floodfill(@img.columns / 2, @img.rows / 2, pixel) }
  end

  def test_color_histogram
    assert_nothing_raised do
      res = @img.color_histogram
      assert_instance_of(Hash, res)
    end
    assert_nothing_raised do
      @img.class_type = Magick::PseudoClass
      res = @img.color_histogram
      expect(@img.class_type).to eq(Magick::PseudoClass)
      assert_instance_of(Hash, res)
    end
  end

  def test_colorize
    assert_nothing_raised do
      res = @img.colorize(0.25, 0.25, 0.25, 'red')
      assert_instance_of(Magick::Image, res)
    end
    assert_nothing_raised { @img.colorize(0.25, 0.25, 0.25, 0.25, 'red') }
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { @img.colorize(0.25, 0.25, 0.25, pixel) }
    assert_nothing_raised { @img.colorize(0.25, 0.25, 0.25, 0.25, pixel) }
    expect { @img.colorize }.to raise_error(ArgumentError)
    expect { @img.colorize(0.25) }.to raise_error(ArgumentError)
    expect { @img.colorize(0.25, 0.25) }.to raise_error(ArgumentError)
    expect { @img.colorize(0.25, 0.25, 0.25) }.to raise_error(ArgumentError)
    expect { @img.colorize(0.25, 0.25, 0.25, 'X') }.to raise_error(ArgumentError)
    # last argument must be a color name or pixel
    expect { @img.colorize(0.25, 0.25, 0.25, 0.25) }.to raise_error(TypeError)
    expect { @img.colorize(0.25, 0.25, 0.25, 0.25, 'X') }.to raise_error(ArgumentError)
    expect { @img.colorize(0.25, 0.25, 0.25, 0.25, [2]) }.to raise_error(TypeError)
  end

  def test_colormap
    # IndexError b/c @img is DirectClass
    expect { @img.colormap(0) }.to raise_error(IndexError)
    # Read PseudoClass image
    pc_img = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    assert_nothing_raised { pc_img.colormap(0) }
    ncolors = pc_img.colors
    expect { pc_img.colormap(ncolors + 1) }.to raise_error(IndexError)
    expect { pc_img.colormap(-1) }.to raise_error(IndexError)
    assert_nothing_raised { pc_img.colormap(ncolors - 1) }
    res = pc_img.colormap(0)
    assert_instance_of(String, res)

    # test 'set' operation
    assert_nothing_raised do
      old_color = pc_img.colormap(0)
      res = pc_img.colormap(0, 'red')
      expect(res).to eq(old_color)
      res = pc_img.colormap(0)
      expect(res).to eq('red')
    end
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { pc_img.colormap(0, pixel) }
    expect { pc_img.colormap }.to raise_error(ArgumentError)
    expect { pc_img.colormap(0, pixel, Magick::BlackChannel) }.to raise_error(ArgumentError)
    expect { pc_img.colormap(0, [2]) }.to raise_error(TypeError)
    pc_img.freeze
    expect { pc_img.colormap(0, 'red') }.to raise_error(FreezeError)
  end

  def test_color_point
    assert_nothing_raised do
      res = @img.color_point(0, 0, 'red')
      assert_instance_of(Magick::Image, res)
      assert_not_same(@img, res)
    end
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { @img.color_point(0, 0, pixel) }
  end

  def test_color_reset!
    assert_nothing_raised do
      res = @img.color_reset!('red')
      assert_same(@img, res)
    end
    pixel = Magick::Pixel.new(Magick::QuantumRange)
    assert_nothing_raised { @img.color_reset!(pixel) }
    expect { @img.color_reset!([2]) }.to raise_error(TypeError)
    expect { @img.color_reset!('x') }.to raise_error(ArgumentError)
    @img.freeze
    expect { @img.color_reset!('red') }.to raise_error(FreezeError)
  end

  def test_compare_channel
    img1 = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
    img2 = Magick::Image.read(IMAGES_DIR + '/Button_1.gif').first

    Magick::MetricType.values do |metric|
      assert_nothing_raised { img1.compare_channel(img2, metric) }
    end
    expect { img1.compare_channel(img2, 2) }.to raise_error(TypeError)
    expect { img1.compare_channel }.to raise_error(ArgumentError)

    ilist = Magick::ImageList.new
    ilist << img2
    assert_nothing_raised { img1.compare_channel(ilist, Magick::MeanAbsoluteErrorMetric) }

    assert_nothing_raised { img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric, Magick::RedChannel) }
    assert_nothing_raised { img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric, Magick::RedChannel, Magick::BlueChannel) }
    expect { img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric, 2) }.to raise_error(TypeError)
    expect { img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric, Magick::RedChannel, 2) }.to raise_error(TypeError)

    res = img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric)
    assert_instance_of(Array, res)
    assert_instance_of(Magick::Image, res[0])
    assert_instance_of(Float, res[1])

    img2.destroy!
    expect { img1.compare_channel(img2, Magick::MeanAbsoluteErrorMetric) }.to raise_error(Magick::DestroyedImageError)
  end
end

if $PROGRAM_NAME == __FILE__
  IMAGES_DIR = '../doc/ex/images'
  FILES = Dir[IMAGES_DIR + '/Button_*.gif']
  Test::Unit::UI::Console::TestRunner.run(Image1UT)
end
