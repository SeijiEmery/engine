module engine.utils.math;
public import gl3n.linalg;
public import std.math;

auto depth (T)(Matrix!(T,4,4) matrix) {
    return matrix.matrix[3][2];
}
