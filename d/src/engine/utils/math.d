module engine.utils.math;
public import gl3n.linalg;
public import std.math;

pure auto depth (T)(Matrix!(T,4,4) matrix) {
    return matrix.matrix[3][2];
}
pure auto lerp (T, S)(T a, T b, S v) 
in {
    //import std.format: format;
    //assert(v >= 0.0 && v <= 1.0, format("%s is not bounded on [0, 1]!", v));
} body {
    return a * v + b * (1.0 - v);
}
int cmp (T)(T a, T b) { return a - b; }
