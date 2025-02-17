# Game Master

Game engine in Mojo programming language

Just SDL and WebGPU glued together atm. SDL is used for SDL things like creating the window and receiving input. WebGPU is used for graphics.

<img width="752" alt="A triangle with a red corner, a green corner, and a blue corner, on a pinkish background." src="https://github.com/user-attachments/assets/b0bf62e0-51be-442b-b84b-acf96828997d" />

## But why tho?

In lots of game engines you either need to learn both a systems programming language and a scripting language, or you are stuck with the drawbacks in one language. I'm motivated by Mojo's versatility--combining the usability of a high-level programming language with the performance of a system programming language. The idea of writing a script and refining/refactoring it in place sounds like a dream for game development. I'm new to Mojo and I'm optimistic. We'll see how it pans out. I specifically have an eye out for namespaces getting polluted with low-level noise when programming at a higher level (may just require careful management), and how often low-level concerns like object lifetimes crop up during higher-level development.

## Principles

- Access to as much source code as possible.
- Leverage purpose-built libraries and editors.
- Pick and choose layers and systems you want to opt-into for your project.
- Write everything (but shaders) in one language, Mojo.

## How to run
1. If you don't have the magic CLI yet, you can install it on macOS and Ubuntu Linux with this command:  
`curl -ssL https://magic.modular.com/deb1184a-ca3b-4724-bd28-040a60337414 | bash`  
Then run the source command that's printed in your terminal.  
1. Run the Game Master example with this command:  
`magic run example`

## How make game?

The idea right now is that you would fork the engine repo and create project files under the root directory, or add the engine repo as a submodule. Then `rebase` or `submodule update` to update the engine in your project. You have access to all of the source code down to the library bindings.
