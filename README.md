# PBS
### Time Analysis

On being run on a double CPU, the data obtained is as follows ➖

- Average run time = 8
- Average wait time = 130

## Static Priority (SP):

### Deterministic Prioritization: 
  SP offers a straightforward and deterministic way to assign priorities to processes. Lower SP values represent higher priorities. This allows for clear and explicit prioritization based on user-defined preferences.

### Preemption Control:  
  SP can be used to manage preemption effectively. Processes with higher SP values can preempt processes with lower SP values. This is particularly useful in real-time systems where certain tasks must have guaranteed access to system resources.

### Predictable Behavior:
   SP provides predictability in process prioritization, making it easier to reason about system behavior. This is important for applications where consistency and predictability are crucial.

   Risk of Starvation: In systems with a fixed SP, there's a risk of lower-priority processes suffering from starvation if high-priority processes are continually arriving.

## Recent Behavior Index (RBI):

### Adaptability:
   RBI reflects the recent behavior of a process, including its running time, sleeping time, and waiting time. This adaptability helps in addressing the dynamic nature of workloads.

### Balancing Resource Allocation: 
   RBI can help balance resource allocation by considering how long a process has been waiting or blocked. It can help prevent processes from getting stuck in a blocked state for extended periods.

### Mitigating Starvation: 
   By considering factors like waiting time, RBI can mitigate the risk of starvation. Processes that have been waiting for a long time receive an RBI boost, which increases their dynamic priority.

### Fine-Tuning and Optimization: 
   The weights assigned to RTime, STime, and WTime in the RBI calculation can be adjusted to fine-tune the scheduling algorithm. This allows you to give more or less importance to certain aspects of process behavior.

# CAFE SIM
   ### PRINT STATEMENTS IN CODE.