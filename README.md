# Pulse Audio command - switch to next sink
This script is designed to switch your pulse audio output to the next available sink.
You can assign it to a shortcut or bind it directly to a key to have the most comfort
switching your audio output to next sink.

## Install
Download the script:  
`wget https://raw.githubusercontent.com/suabo/pacmd-switch-sink/master/pacmd-switch-sink`  

Optional: Copy it to folder where path variable is pointing to, to call it without the full path:  
`sudo cp pacmd-switch-sink /usr/local/bin/pacmd-switch-sink`

## Usage
Switch to next sink:  
`pacmd-switch-sink`

Switch to next sink ignoring one or multiple sink(s):  
`pacmd-switch-sink -i <VendorID>:<ProductID>`  
ex.  
`pacmd-switch-sink -i 1002:aaf0`

Show short list of all sinks:  
`pacmd-switch-sink -l`

### Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. 
IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE 
BE LIABLE FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, 
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.
