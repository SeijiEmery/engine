module engine.utils.color;
import engine.utils.math;
import std.format: format;
import gl3n.linalg: max, min;

vec4 color (string colorStr) {
    import std.conv: parse;
    if ((colorStr.length == 7 || colorStr.length == 9) && colorStr[0] == '#') {
        auto result = vec4();
        string s;
        s = colorStr[1..3]; result.x = cast(float)parse!int(s, 16) * (1 / 255.0);
        s = colorStr[3..5]; result.y = cast(float)parse!int(s, 16) * (1 / 255.0);
        s = colorStr[5..7]; result.z = cast(float)parse!int(s, 16) * (1 / 255.0);
        if (colorStr.length == 9) {
            s = colorStr[7..9]; result.w = cast(float)parse!int(s, 16) * (1 / 255.0);
        } else {
            result.w = 1.0;
        }
        return result;
    } else {
        switch (colorStr) {
            case "red":   return vec4(1, 0, 0, 1);
            case "green": return vec4(0, 1, 0, 1);
            case "blue":  return vec4(0, 0, 1, 1);        
            case "white":  return vec4(0, 0, 0, 1);        
            case "black":  return vec4(1, 1, 1, 1);        
            default:
        }
        throw new Exception(format("invalid color value: '%s'", colorStr));
    }
}
vec4 withAlpha (vec4 color, float alpha) {
    return vec4(color.r, color.g, color.b, alpha);
}

// imported from gsb
vec4 toHSV (vec4 rgba) {
    auto r = rgba.x, g = rgba.y, b = rgba.z;

    auto M = max(r, g, b);
    auto m = min(r, g, b);
    auto c = M - m;

    float h;
    if (r > max(g, b))      h = fmod((g - b) / c, 6);
    else if (g > max(r, b)) h = (b - r) / c + 2;
    else if (b > max(r, g)) h = (b - r) / c + 4;
    else h = 0.0; // "undefined"; doesn't really matter what this value is though

    float v = M;
    float s = c ? c / v : 0;

    return vec4(h / 6, s, v, rgba.a);
}
// imported from gsb
vec4 fromHSV (vec4 hsva) {
    auto h = hsva.x, s = hsva.y, v = hsva.z;
    
    h *= 6;

    float c = s * v; // chroma
    float x = c * (1 - abs(fmod(h, 2) - 1));
    
    vec4 rgb;
    if      (h <= 1) rgb = vec4(c, x, 0, 0);
    else if (h <= 2) rgb = vec4(x, c, 0, 0);
    else if (h <= 3) rgb = vec4(0, c, x, 0);
    else if (h <= 4) rgb = vec4(0, x, c, 0);
    else if (h <= 5) rgb = vec4(x, 0, c, 0);
    else if (h <= 6) rgb = vec4(c, 0, x, 0);

    auto m = vec4(v - c, v - c, v - c, hsva.a);
    return rgb + m;
}

unittest {
    import engine.utils.asserts;

    assertEq(color("#ff0000"), vec4(1, 0, 0, 1));
    assertEq(color("#ff0000ff"), vec4(1, 0, 0, 1));
    assertEq(color("#ff000000"), vec4(1, 0, 0, 0));
    assertEq(color("#ff0000").withAlpha(0.5), vec4(1, 0, 0, 0.5));
    assertEq(color("red"), color("#ff0000"));

    assertEq(color("red").toHSV.fromHSV, color("red"));
    assertEq(color("green").toHSV.fromHSV, color("green"));
    assertEq(color("blue").toHSV.fromHSV, color("blue"));
    assertEq(color("black").toHSV.fromHSV, color("black"));
    assertEq(color("white").toHSV.fromHSV, color("white"));

    assertEq(vec4(0, 1, 1, 1).fromHSV, color("red"));
    assertEq(vec4(0, 0, 1, 1).fromHSV, color("white"));
    assertEq(vec4(0, 0, 0, 1).fromHSV, color("black"));
    assertEq(vec4(0, 1, 0, 1).fromHSV, color("black"));
}
