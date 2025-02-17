# Game Master

Game engine in Mojo programming language

Just SDL and WebGPU glued together atm.

## But why tho?

In lots of game engines you either need to learn both a systems programming language and a scripting language, or you are stuck with the drawbacks in one language. I'm motivated by Mojo's versatility--combining the usability of a high-level programming language with the performance of a system programming language. The idea of writing a script and refining/refactoring it in place sounds like a dream for game development. I'm new to Mojo and I'm optimistic. We'll see how it pans out. I specifically have an eye out for namespaces getting polluted with low-level noise when programming at a higher level (may just require careful management), and how often low-level concerns like object lifetimes crop up during higher-level development.

## Project Structure

The idea right now is that you would fork the engine repo and create project files under the root directory, or add the engine repo as a submodule. Then `rebase` or `submodule update` to update the engine in your project. You have access to all of the source code down to the library bindings.

## Direction

- Access to as much source code as possible.
- Leverage purpose-built libraries and editors.
- Pick and choose layers and systems you want to opt-into for your project.
- Write everything (but shaders) in one language, Mojo.