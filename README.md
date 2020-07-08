# PsDemoScript

PowerShell module to help and assist you while performing a PowerShell demo.

You want to make sure that you don't have to switch around from your IDE / Editor? Do you want to record your demo scripts, and want to create the same experience as the viewer?

Then this module is for you.

## **Getting started**
### **Install the latest module**

```
Install-Module -Name PsDemoScript
```

### **Update the module**

```
Update-Module -name PsDemoScript
```

### **Update the module - force**

```
Update-Module -name PsDemoScript -Force
```

## **Run a demo**
You need to create a text file containing the demo script that you want to run. The demo file has a few formatting requirements, for you to be able to utilize all the capabilities.

The `"þ"` character is a inline pause signal, that will halt the "writing" to the console, until you press a key. This is to allow you to halt at any point in the script and allow you to explain a concept. E.g.
```PowerShell
Get-ChildItem þ-Path "C:\Windows\System32\" -Exclude þ"*.exe"
```
The above example will halt just before the `-Path` parameter is written to the console. The next halt is just after the `-Exclude` parameter, before the parameter value `"*.exe"` is written to the console.

The `"|"` character is considered a pause signal, that will halt the "writing" to the console, until you press a key. This is to allow you explain what you're about to pipe into the next cmdlet. E.g.
```PowerShell
Get-ChildItem -Path "C:\Windows\System32\" -Exclude "*.exe" | Select-Object -First 10
```
The above example will halt just after the `"|"` character is written to the console.

Whenever the "writing" is halted, you can chose to fast forward, by pressing the `"f"` key on your keyboard, or return to normal speed, by pressing the `"n"` key on your keyboard. This allows you to control the speed of your demo, if you need to move faster through some examples and then return back to normal speed / pace later in the demo.

### **Single line**
As mentioned, you will need to provide a path for a text file containing a valid demo script. Below is a simple single script, that you could copy & paste into a local file on your machine.
```PowerShell
#Will halt 3 times, before -Path, after -Exclude and after |
Get-ChildItem þ-Path "C:\Windows\System32\" -Exclude þ"*.exe" | Select-Object -First 10
```
Let's assume the the file is placed in `"C:\Temp\Demo1.txt"`, you would start a demo like this.
```PowerShell
Import-Module PsDemoScript
Start-PsDemo -Path "C:\Temp\Demo1.txt"
```
### **Multi line**
There is support for handling the classic PowerShell multiline scripts, where the backtick ("\`") is letting you continue the script on the next line.

It is enabled by adding `"::"` as a line before the multiline script and after the multiline script. Below is a simple single script, that you could copy & paste into a local file on your machine.
```PowerShell
::
#Will allow the demo to write the script as a multiline example to the console
Get-ChildItem -Path "C:\Windows\System32\" `
-Exclude "*.exe"
::
```
The above script doesn't is just showing how multiline works, it doesn't show how to handle halts in the script. You can combine halt and multiline anyway you want.

Let's assume the the file is placed in `"C:\Temp\Demo2.txt"`, you would start a demo like this.
```PowerShell
Import-Module PsDemoScript
Start-PsDemo -Path "C:\Temp\Demo2.txt"
```

### **Control the speed of typing**
Running a demo and make it look and feel like a human is typing along, is all about the pause/timing between the characters being written to the console.

You can control this as a configuration with the `Set-PsDemoTypingSpeed` cmdlet, that will overwrite the default configuration. This allows you find the perfect typing speed, and store it. Whenever you run a demo going forward, it will use the default.

You can still override the typing speed per demo invocation, with the `-TypingSpeed` parameter.

The typing speed is being measured in milliseconds, which offers great flexibilities to hit the sweet spot the feels right for you.

### **To run or not to run**
Running a demo several times might be a cumbersome task while you're adjusting the demo scripts, either because is simply takes time or because the objects / resources that you depend on might be unavailable.

The module has a concept of mode, which translates into a run mode. The modes available are: `"Execute"`, `"Echo"` or `"Silent"`.

Execute allows you to run the script, while you demo it. This will yield output to the console, just like you would expect.

Echo allows you to the the command/script echoed back to the console, as a double check or double confirm. Nothing will be executed and console will contain the same statement twice, once for the demo being typed and once for the echo just after that.

Silent allows you to mimic the execution of the demo, but without bloating the console or execution the demo script.

You can control this as a configuration with the `Set-PsDemoMode` cmdlet, that will overwrite the default configuration. This allows you set the mode going forward, like when switching to presentation mode, and store it. Whenever you run a demo going forward, it will use the default.

You can still override the mode per demo invocation, with the `-Mode` parameter.

### **Fake it till you make it**
Do you need to run some demos with sensitive data, credentials or just want to control the output during the demo?

The module supports a MockCommandsFile, which allows you to override the cmdlets / functions that your demo will be running. That way you can run a demo, with fake credentials, but use a saved output from an earlier run. You can also override a simple function, and make it behave like you need to.

An example for this could be `Get-ChildItem -Path "C:\Temp"`, you might have some files and folders that you don't want the audience to see, you could then have prepped the output in a `.ps1` file.

Below example shows you how to run a demo and have it use a mocked `.ps1` file.
```PowerShell
Import-Module PsDemoScript
Start-PsDemo -Path "C:\Temp\Demo3.txt" -MockCommandsFile "C:\Temp\Demo3_Mocked.ps1"
```