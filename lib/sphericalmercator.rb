class SphericalMercator

  attr_accessor :Bc, :Cc, :zc, :Ac

  @@cache = {

  }

  EPSLN =  1.0e-10, 
  D2R = Math::PI / 180.0, 
  R2D = 180.0 / Math::PI, 
  A = 6378137.0, 
  MAXEXTENT = 20037508.342789244

  def initialize(options = {})
    @size = options[:size] || 256
    if !@@cache[@size]
      c = {}
      c[:Bc] = []
      c[:Cc] = []
      c[:zc] = []
      c[:Ac] = []

      size = @size
      30.times do 
        c[:Bc].push(size / 360.0)
        c[:Cc].push(size / (2*Math::PI))
        c[:zc].push(size / 2.0)
        c[:Ac].push(size)
        size = size*2
      end
      @@cache[@size] = c
    end

    self.Bc = @@cache[@size][:Bc]
    self.Cc = @@cache[@size][:Cc]
    self.zc = @@cache[@size][:zc]
    self.Ac = @@cache[@size][:Ac]
  end

  def xyz(bbox, zoom)
    ll = [bbox[0], bbox[1]]
    ur = [bbox[2], bbox[3]]
    px_ll = px(ll, zoom)
    px_ur = px(ur, zoom)

    x = [(px_ll[0] / @size).floor, ((px_ur[0]-1) / @size).floor]
    y = [(px_ur[1] / @size).floor, ((px_ll[1]-1) / @size).floor]

    bounds = {
      minX: ((x.min < 0) ? 0 : x.min),
      minY: ((y.min < 0) ? 0 : y.min), 
      maxX: x.max, 
      maxY: y.max
    }

    bounds
  end

  def bbox(x, y, zoom, tms_style = false)
    y = ((zoom**2) - 1) - y if tms_style
    _ll = [x * @size, (y + 1)*@size]
    _ur = [(x+1)*@size, y*@size]
    bbox = ll(_ll, zoom).concat(ll(_ur, zoom))
    bbox
  end

  def ll(px, zoom)
    if zoom.is_a?(Float)
      size = @size * (2**zoom)
      bc = size / 360.0
      cc = (size / (2.0*Math::PI))
      zc = size / 2.0
      g = (px[1] - zc) / -cc
      lon = (px[0] - zc) / bc
      lat = R2D * (2.0 * Math.atan(Math.exp(g)) - (0.5 * Math::PI)) 
      [lon ,lat]
    else
      g = (px[1] - self.zc[zoom]) / (-self.Cc[zoom])
      lon = (px[0] - self.zc[zoom]) / self.Bc[zoom]
      lat = R2D * (2.0 * Math.atan(Math.exp(g)) - (0.5 * Math::PI)) 
      [lon, lat]
    end
  end

  def px(ll, zoom)
    if zoom.is_a?(Float)
      size = @size * (2**zoom)
      d = size / 2.0
      bc = (size / 360.0)
      cc = (size / (2.0 * Math::PI))
      ac = size
      f = [0.9999, [Math.sin(D2R * ll[1]), -0.9999].max].min
      x = d + ll[0] * bc
      y = d + 0.5 * Math.log((1+f) / (1-f)) * -cc
      (x > ac) && (x = ac);
      (y > ac) && (y = ac);
      return [x, y];
    else
      d = self.zc[zoom]
      f = [0.9999, [Math.sin(D2R * ll[1]), -0.9999].max].min
      x = (d + ll[0] * self.Bc[zoom]).round
      y = (d + 0.5 * Math.log((1+f)/(1-f)) * (-self.Cc[zoom])).round
      (x > self.Ac[zoom]) && (x = self.Ac[zoom]);
      (y > self.Ac[zoom]) && (y = self.Ac[zoom]);
      return [x, y];
    end
  end

end