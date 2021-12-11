# DES Encryption and Decryption in 64 bits

**Brendan Moran and Dhruv Birla**
**Fall 2021**
**ECE 287 B w/ Dr. Peter Jamieson**

### High-Level Description
At a high level, our project lets the user enter a 64-bit key followed by a 64-bit message and allows them to choose to either encrypt or decrypt the input text with the key they entered. This is done using the on-board switches for inputing values, buttons to send the data entered using the switches and switch through different states, and a seven-segment decoder for displaying the current input as well as the output at the end.

### Background Information
DES was the most popular encryption algorithm for almost two decades and its usage spanned across several industries such as banking, communication, and data storage. It has laid the foundation for other methods of encryption as DES alone doesn’t stand up against modern computing power. We chose to implement this algorithm on an FPGA due to our interest surrounding the inner workings of encryption and decryption at the bit-level.

### Description
The actual module used for encryption and decryption is just a large combinational circuit. It takes in a 64-bit key, 64-bit value, and a one bit encryption/decryption indicator and outputs a 64-bit message. A series of registers hold the message bits at each stage of the process, and they are connected using combinational logic to transform these bits. 

The initial step of the process is to create 16 sub-keys of 48 bits from the 64-bit key. This is done by first taking a 56-bit permutation of the original key, splitting the new key into equal left and right halves, and applying a series of one or two left shifts 16 times to the left and right halves individually. Each new pair of shifted left and right halves are concatenated and a final 48-bit permutation is applied to each 56-bit concatenation to produce 16 keys of 48 bits each.

Next, we use the keys to encrypt or decrypt our message. This process starts by applying a 64-bit permutation to the message and splitting it into left and right halves, similar to the keys. Then, 16 chunks of left and right pairs are created by applying a function to the pair before it, starting with the original pair. The left half of the next chunk is just the right half of the previous chunk, but finding the next chunk’s right half is a bit more involved. 

Determining the next right half starts by taking a 48 bit permutation of the previous right half. The new permutation is then XOR’d with the key of the same index. For decryption, the key sequence is reversed so the key applied would be 16 minus the index. This results in a sequence of 48 bits, or eight groups of six bits. Each of these groups corresponds to an s-box, which is a 4x16 data structure of four-bit elements. 

Each group of six bits is replaced with a four bit element from the corresponding s-box by using the outer two bits as a row index and the inner four bits as the column index to retrieve the four bit element. Now that each of the eight six-bit elements are replaced with four bit elements, we have a sequence of 32 bits. Finally, this sequence is XOR’d with the previous left half to produce the current right half. 

The last step is to take the 16th pair of 32 bit sequences, concatenate them (with the right half coming before the left half) and apply a final 64-bit permutation to produce the output message.

### Design
Our program has 24 states. The first is START which is entered on reset. When the user selects one of two buttons indicating encryption or decryption, the mode is determined and the first key state is entered. There are four key states that let the user enter 16 bits of the 64-bit key at a time and view their selection on the seven segment decoder as a hex value. Between each of these key states is a waiting state that is entered and exited on a button press and release. When a waiting state is entered, the current key segment is stored. The last waiting state follows into a display key state which lets the user view the four segments of their key using two switches. 

This same process is repeated to allow the user to enter a 64-bit value to encrypt or decrypt. After another button press and release, the final 64-bit output is displayed on the seven-segment display, which can be viewed in its entirety using two switches.

### Conclusion
Overall, the project is a simple but fully functional device for encrypting and decrypting 64-bit chunks of information using hardware. The most challenging part of development was designing a physical system to replicate steps of an algorithm as well as debugging tiny errors among thousands of bit manipulations that produce wildly different results.

### Citations
*Grabbe, O. (n.d.). The DES Algorithm Illustrated. Retrieved December 11, 2021, from https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm.*

