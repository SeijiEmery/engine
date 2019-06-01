# engine-rs

A tiny toy 2d game engine / game framework written in rust.

Features:

 - tiny 2d renderer implemented using glium
 - ECS implementation from specs
 - utilites for dealing with time, colors, cameras, etc
 - sufficient for small examples / game demos (up to and including pong... >_<)

## Build instructions:

To run examples:

	git clone https://github.com/SeijiEmery/engine.git
	cd rs
	cargo run --example empty_window
	cargo run --example render_test
	cargo run --example depth_test
	cargo run --example pong_demo

Note that as an alternative you can run these from CLion (with the official Rust plugin from jetbrains).

To install the rust toolchain: <https://www.rust-lang.org/tools/install>

note: if on osx I'd honestly recommend just running `brew install rust`. Or `rustup`, as above...

## Examples:

#### Empty window:

Minimal example of how to write a demo project. Prints all window events, which is helpful for debugging (or determining what events correspond to specific keystrokes, etc)


#### Render test:

Tests render primitives and showcases ECS capabilities via systems that apply rotation and oscillate position / scale / colors / etc.


#### Depth test:

Tests that transparency + depth are working correctly.


#### Pong demo:

Minimal implementation of pong. Currently doesn't handle scoring or a game over state. 2 player: uses WASD and arrow keys for the two players.






