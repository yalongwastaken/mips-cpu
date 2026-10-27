"""Render a GDS's signal routing and power grid to a PNG, in KLayout batch mode.

Usage:
    klayout -b -r render_layout.py -rd gds=<in.gds> -rd lyp=<pdk.lyp> \\
        -rd png=<out.png>

The layer colors come from the PDK's own KLayout layer properties. Only metal 2
through 5 are shown: the cells and metal 1 cover the whole die at this scale
and hide the routing.
"""

import pya

# SkyWater 130 GDS layer and datatype of metal 2 through 5, drawing purpose
SHOWN_LAYERS = {(69, 20), (70, 20), (71, 20), (72, 20)}
IMAGE_SIDE_PIXELS = 1400

gds_path, lyp_path, png_path = gds, lyp, png  # noqa: F821, KLayout defines these from -rd

layout_view = pya.LayoutView()
layout_view.load_layout(gds_path, 0)
layout_view.max_hier()
layout_view.load_layer_props(lyp_path)
layer_iterator = layout_view.begin_layers()
while not layer_iterator.at_end():
    layer_properties = layer_iterator.current()
    layer_properties.visible = (
        layer_properties.source_layer,
        layer_properties.source_datatype,
    ) in SHOWN_LAYERS
    layout_view.set_layer_properties(layer_iterator, layer_properties)
    layer_iterator.next()
layout_view.set_config("background-color", "#ffffff")
layout_view.zoom_fit()
layout_view.save_image(png_path, IMAGE_SIDE_PIXELS, IMAGE_SIDE_PIXELS)
