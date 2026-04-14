# task scheduler scripts
## script 1: triggerAndAction.ps1
for a single task, provide info for:
 - wnf task triggers
 - eventlog based triggers
 - actions: clsid based or exe x args
 - hashes for exes and dlls

## script 2: get-scheduledtaskdata.ps1
enumerate all tasks and provide info for:
 - wnf task triggers
 - eventlog based triggers
 - actions: clsid based or exe x args
 - hashes for exes and dlls

## nicities
  - when a task is started with service control (sc) it digs deeper on the service
  - the hashes returned are sha256, but it's trivial to get another algo


## TODO: 
 - include WNFlist in script instead of separate file
 - normal (time based) triggers
 - csv output option (what data to include)

## Idea
I wanted to check scheduled tasks for irregularities. I saw a lot of 'obfuscation', 
maybe not the right word, but things that were unclear to me.
Learned a lot about pwsh and the way tasks work.
## Sources
* wnf triggers: https://github.com/rbmm/WnfNames/
* idea source: camille debay (https://debay.blog/2019/11/11/wnf-and-task-scheduler/)
* microsoft docs...
