require 'fileutils'
require 'rmagick'
require 'minitest/autorun'

class ImageList2UT < Minitest::Test
  def setup
    @ilist = Magick::ImageList.new
  end

  def test_append
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_0.gif')
    assert_nothing_raised do
      img = @ilist.append(true)
      assert_instance_of(Magick::Image, img)
    end
    assert_nothing_raised do
      img = @ilist.append(false)
      assert_instance_of(Magick::Image, img)
    end
    expect { @ilist.append }.to raise_error(ArgumentError)
    expect { @ilist.append(true, 1) }.to raise_error(ArgumentError)
  end

  def test_average
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_0.gif')
    assert_nothing_raised do
      img = @ilist.average
      assert_instance_of(Magick::Image, img)
    end
    expect { @ilist.average(1) }.to raise_error(ArgumentError)
  end

  def test_clone
    @ilist.read(*Dir[IMAGES_DIR + '/Button_*.gif'])
    ilist2 = @ilist.clone
    expect(@ilist).to eq(ilist2)
    expect(ilist2.frozen?).to eq(@ilist.frozen?)
    expect(ilist2.tainted?).to eq(@ilist.tainted?)
    @ilist.taint
    @ilist.freeze
    ilist2 = @ilist.clone
    expect(ilist2.frozen?).to eq(@ilist.frozen?)
    expect(ilist2.tainted?).to eq(@ilist.tainted?)
  end

  def test_coalesce
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_0.gif')
    ilist = nil
    assert_nothing_raised { ilist = @ilist.coalesce }
    assert_instance_of(Magick::ImageList, ilist)
    expect(ilist.length).to eq(2)
    expect(ilist.scene).to eq(0)
  end

  def test_copy
    @ilist.read(*Dir[IMAGES_DIR + '/Button_*.gif'])
    @ilist.scene = 7
    ilist2 = @ilist.copy
    assert_not_same(@ilist, ilist2)
    expect(ilist2.scene).to eq(@ilist.scene)
    @ilist.each_with_index do |img, x|
      expect(ilist2[x]).to eq(img)
    end
  end

  def test_deconstruct
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    ilist = nil
    assert_nothing_raised { ilist = @ilist.deconstruct }
    assert_instance_of(Magick::ImageList, ilist)
    expect(ilist.length).to eq(2)
    expect(ilist.scene).to eq(0)
  end

  def test_dup
    @ilist.read(*Dir[IMAGES_DIR + '/Button_*.gif'])
    ilist2 = @ilist.dup
    expect(@ilist).to eq(ilist2)
    expect(ilist2.frozen?).to eq(@ilist.frozen?)
    expect(ilist2.tainted?).to eq(@ilist.tainted?)
    @ilist.taint
    @ilist.freeze
    ilist2 = @ilist.dup
    assert_not_equal(@ilist.frozen?, ilist2.frozen?)
    expect(ilist2.tainted?).to eq(@ilist.tainted?)
  end

  def flatten_images
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    assert_nothing_thrown do
      img = @ilist.flatten_images
      assert_instance_of(Magick::Image, img)
    end
  end

  def test_from_blob
    hat = File.open(FLOWER_HAT, 'rb')
    blob = hat.read
    assert_nothing_raised { @ilist.from_blob(blob) }
    assert_instance_of(Magick::Image, @ilist[0])
    expect(@ilist.scene).to eq(0)

    ilist2 = Magick::ImageList.new(FLOWER_HAT)
    expect(ilist2).to eq(@ilist)
  end

  def test_marshal
    ilist1 = Magick::ImageList.new(*Dir[IMAGES_DIR + '/Button_*.gif'])
    d = nil
    ilist2 = nil
    assert_nothing_raised { d = Marshal.dump(ilist1) }
    assert_nothing_raised { ilist2 = Marshal.load(d) }
    expect(ilist2).to eq(ilist1)
  end

  def test_montage
    @ilist.read(*Dir[IMAGES_DIR + '/Button_*.gif'])
    ilist = @ilist.copy
    montage = nil
    assert_nothing_thrown do
      montage = ilist.montage do
        self.background_color = Magick::Pixel.new(Magick::QuantumRange, 0, 0)
        self.background_color = 'blue'
        self.border_color = Magick::Pixel.new(0, 0, 0)
        self.border_color = 'red'
        self.border_width = 2
        self.compose = Magick::OverCompositeOp
        self.filename = 'test.png'
        self.fill = 'green'
        self.font = Magick.fonts.first.name
        self.frame = '20x20+4+4'
        self.frame = Magick::Geometry.new(20, 20, 4, 4)
        self.geometry = '63x60+5+5'
        self.geometry = Magick::Geometry.new(63, 60, 5, 5)
        self.gravity = Magick::SouthGravity
        self.matte_color = '#bdbdbd'
        self.matte_color = Magick::Pixel.new(Magick::QuantumRange, 0, 0)
        self.pointsize = 12
        self.shadow = true
        self.stroke = 'transparent'
        self.texture = Magick::Image.read(IMAGES_DIR + '/Button_0.gif').first
        self.texture = Magick::Image.read(IMAGES_DIR + '/Button_1.gif').first
        self.tile = '4x9'
        self.tile = Magick::Geometry.new(4, 9)
        self.title = 'sample'
      end
      assert_instance_of(Magick::ImageList, montage)
      expect(ilist).to eq(@ilist)

      montage_image = montage.first
      expect(montage_image.background_color).to eq('blue')
      expect(montage_image.border_color).to eq('red')
    end

    # test illegal option arguments
    # looks like IM doesn't diagnose invalid geometry args
    # to tile= and geometry=
    expect do
      montage = ilist.montage { self.background_color = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.border_color = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.border_width = [2] }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.compose = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.filename = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.fill = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.font = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.gravity = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.matte_color = 2 }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.pointsize = 'x' }
      expect(ilist).to eq(@ilist)
    end.to raise_error(TypeError)
    expect do
      montage = ilist.montage { self.stroke = 'x' }
      expect(ilist).to eq(@ilist)
    end.to raise_error(ArgumentError)
    expect do
      montage = ilist.montage { self.texture = 'x' }
      expect(ilist).to eq(@ilist)
    end.to raise_error(NoMethodError)
  end

  def test_morph
    # can't morph an empty list
    expect { @ilist.morph(1) }.to raise_error(ArgumentError)
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    # can't specify a negative argument
    expect { @ilist.morph(-1) }.to raise_error(ArgumentError)
    assert_nothing_raised do
      res = @ilist.morph(2)
      assert_instance_of(Magick::ImageList, res)
      expect(res.length).to eq(4)
      expect(res.scene).to eq(0)
    end
  end

  def test_mosaic
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    assert_nothing_thrown do
      res = @ilist.mosaic
      assert_instance_of(Magick::Image, res)
    end
  end

  def test_mosaic_with_invalid_imagelist
    list = @ilist.copy
    list.instance_variable_set("@images", nil)
    expect { list.mosaic }.to raise_error(Magick::ImageMagickError)
  end

  def test_new_image
    assert_nothing_raised do
      @ilist.new_image(20, 20)
    end
    expect(@ilist.length).to eq(1)
    expect(@ilist.scene).to eq(0)
    @ilist.new_image(20, 20, Magick::HatchFill.new('black'))
    expect(@ilist.length).to eq(2)
    expect(@ilist.scene).to eq(1)
    @ilist.new_image(20, 20) { self.background_color = 'red' }
    expect(@ilist.length).to eq(3)
    expect(@ilist.scene).to eq(2)
  end

  def test_optimize_layers
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    Magick::LayerMethod.values do |method|
      next if [Magick::UndefinedLayer, Magick::CompositeLayer, Magick::TrimBoundsLayer].include?(method)

      assert_nothing_raised do
        res = @ilist.optimize_layers(method)
        assert_instance_of(Magick::ImageList, res)
        assert_kind_of(Integer, res.length)
      end
    end

    assert_nothing_raised { @ilist.optimize_layers(Magick::CompareClearLayer) }
    expect { @ilist.optimize_layers(Magick::UndefinedLayer) }.to raise_error(ArgumentError)
    expect { @ilist.optimize_layers(2) }.to raise_error(TypeError)
    expect { @ilist.optimize_layers(Magick::CompositeLayer) }.to raise_error(NotImplementedError)
  end

  def test_ping
    assert_nothing_raised { @ilist.ping(FLOWER_HAT) }
    expect(@ilist.length).to eq(1)
    expect(@ilist.scene).to eq(0)
    assert_nothing_raised { @ilist.ping(FLOWER_HAT, FLOWER_HAT) }
    expect(@ilist.length).to eq(3)
    expect(@ilist.scene).to eq(2)
    assert_nothing_raised { @ilist.ping(FLOWER_HAT) { self.background_color = 'red ' } }
    expect(@ilist.length).to eq(4)
    expect(@ilist.scene).to eq(3)
  end

  def test_quantize
    @ilist.read(IMAGES_DIR + '/Button_0.gif', IMAGES_DIR + '/Button_1.gif')
    assert_nothing_raised do
      res = @ilist.quantize
      assert_instance_of(Magick::ImageList, res)
      expect(res.scene).to eq(1)
    end
    assert_nothing_raised { @ilist.quantize(128) }
    expect { @ilist.quantize('x') }.to raise_error(TypeError)
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace) }
    expect { @ilist.quantize(128, 'x') }.to raise_error(TypeError)
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, true, 0) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, true) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, false) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::NoDitherMethod) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::RiemersmaDitherMethod) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::FloydSteinbergDitherMethod) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::FloydSteinbergDitherMethod, 32) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::FloydSteinbergDitherMethod, 32, true) }
    assert_nothing_raised { @ilist.quantize(128, Magick::RGBColorspace, Magick::FloydSteinbergDitherMethod, 32, false) }
    expect { @ilist.quantize(128, Magick::RGBColorspace, true, 'x') }.to raise_error(TypeError)
    expect { @ilist.quantize(128, Magick::RGBColorspace, true, 0, false, 'extra') }.to raise_error(ArgumentError)
  end

  def test_read
    assert_nothing_raised { @ilist.read(FLOWER_HAT) }
    expect(@ilist.length).to eq(1)
    expect(@ilist.scene).to eq(0)
    assert_nothing_raised { @ilist.read(FLOWER_HAT, FLOWER_HAT) }
    expect(@ilist.length).to eq(3)
    expect(@ilist.scene).to eq(2)
    assert_nothing_raised { @ilist.read(FLOWER_HAT) { self.background_color = 'red ' } }
    expect(@ilist.length).to eq(4)
    expect(@ilist.scene).to eq(3)
  end

  def test_remap
    @ilist.read(*Dir[IMAGES_DIR + '/Button_*.gif'])
    assert_nothing_raised { @ilist.remap }
    remap_image = Magick::Image.new(20, 20) { self.background_color = 'green' }
    assert_nothing_raised { @ilist.remap(remap_image) }
    assert_nothing_raised { @ilist.remap(remap_image, Magick::NoDitherMethod) }
    assert_nothing_raised { @ilist.remap(remap_image, Magick::RiemersmaDitherMethod) }
    assert_nothing_raised { @ilist.remap(remap_image, Magick::FloydSteinbergDitherMethod) }
    expect { @ilist.remap(remap_image, Magick::NoDitherMethod, 1) }.to raise_error(ArgumentError)

    remap_image.destroy!
    expect { @ilist.remap(remap_image) }.to raise_error(Magick::DestroyedImageError)
    # expect { @ilist.affinity(affinity_image, 1) }.to raise_error(TypeError)
  end

  def test_to_blob
    @ilist.read(IMAGES_DIR + '/Button_0.gif')
    blob = nil
    assert_nothing_raised { blob = @ilist.to_blob }
    img = @ilist.from_blob(blob)
    expect(img[0]).to eq(@ilist[0])
    expect(img.scene).to eq(1)
  end

  def test_write
    @ilist.read(IMAGES_DIR + '/Button_0.gif')
    assert_nothing_raised do
      @ilist.write('temp.gif')
    end
    list = Magick::ImageList.new('temp.gif')
    expect(list.format).to eq('GIF')
    FileUtils.rm('temp.gif')

    @ilist.write('jpg:temp.foo')
    list = Magick::ImageList.new('temp.foo')
    expect(list.format).to eq('JPEG')
    FileUtils.rm('temp.foo')

    @ilist.write('temp.0') { self.format = 'JPEG' }
    list = Magick::ImageList.new('temp.0')
    expect(list.format).to eq('JPEG')
    FileUtils.rm('temp.0')

    f = File.new('test.0', 'w')
    @ilist.write(f) { self.format = 'JPEG' }
    f.close
    list = Magick::ImageList.new('test.0')
    expect(list.format).to eq('JPEG')
    FileUtils.rm('test.0')
  end
end

if $PROGRAM_NAME == __FILE__
  IMAGES_DIR = '../doc/ex/images'
  FLOWER_HAT = IMAGES_DIR + '/Flower_Hat.jpg'
  Test::Unit::UI::Console::TestRunner.run(ImageList2UT)
end
