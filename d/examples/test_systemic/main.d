import std.stdio: writefln;

mixin generate_systemic!(
    q{  Rotator r, DeltaTime dt -> RotationAngle angle },
    q{  angle += r.speed * dt   });

mixin generate_systemic!(q{
    Rotator r, DeltaTime dt -> RotationAngle angle {
        angle += r.speed * dt;
    }
});

mixin generate_systemic!(
    systemic_typelist!(
        systemic_typedecl!("Rotator", "r", SystemicParam.In),
        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
        systemic_typedecl!("RotationAngle", "angle", SystemicParam.Out),
    ),
    systemic_bodyexpr!(q{
        angle += r.speed * dt;
    })
);

mixin(grammar(q{
TypeDecl:
    Type < identifier
    Var  < identifier
    VT   < Type Var
    VTList < VT / (VT "," VTList)
    TypeDecl < VTList "->" VTList / VTList / "->" VTList
}));

void main () {}
