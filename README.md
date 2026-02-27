# Frame

## Description
Program draws frame with text in the center of screen.
Before drawing the frame, it cleans the screen.

Supposed to be ran on DOSBox.

## Build
For compilation use Turbo Assembler (TASM):
```powershell
tasm /la pr_cd_st.asm
tlink /t pr_cd_st.obj
```

# Run program

## Format
```powershell
    pr_cd_st.com <Text> '/' <FrameStyleSymbol (optional)>
```

## Examples

### Example 1
Draw a frame with standard borders style with text "Standard Example"
```powershell
    pr_cd_st.com Standard Example
```
![example](https://github.com/mmmxxxaaa/asm_strings/raw/5559dd62f97f3e0687f5ea1f4d4295490694b5f4/example_1.png)


### Example 2
Draw a frame consisting of a character specified by the user with text "Specified Example"
```powershell
    pr_cd_st.com Specified Example/@
```
![example](https://github.com/mmmxxxaaa/asm_strings/raw/5559dd62f97f3e0687f5ea1f4d4295490694b5f4/example_2.png)
