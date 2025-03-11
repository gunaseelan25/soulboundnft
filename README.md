### **SRM SoulBound NFT Module**  
A Move module for managing a **Soul-Bound NFT Collection** on Aptos. This contract allows an admin to **initialize**, **mint**, and **track NFTs** that cannot be transferred after minting.

---

## **📌 Features**
- **Collection Management**: Admin can initialize an NFT collection.  
- **Soul-Bound Minting**: NFTs are non-transferable once minted.  
- **Event Logging**: Tracks each minting event.  
- **Supply Management**: Keeps count of minted and remaining NFTs.  

---

## **🛠 Installation**
1. **Clone the Repository**
   ```sh
   git clone https://github.com/gunaseelan25/soulboundnft.git
   cd soulboundnft
   ```
2. **Ensure Move CLI & Aptos Framework are Installed**  
   If you haven’t set up Aptos Move:
   ```sh
   aptos init
   ```
3. **Compile the Module**
   ```sh
   aptos move compile
   ```
4. **Publish the Move Contract**
   ```sh
   aptos move publish
   ```

---

## **🚀 Usage**
### **1️⃣ Initialize the Collection**
Only the admin can initialize the collection.
```move
srm_test::srm_test_sbt::initialize(&signer);
```
This:
- Creates a **resource account**.
- Stores metadata like **name, description, and URI**.
- Initializes minting events and supply tracking.

### **2️⃣ Mint a Soul-Bound NFT**
```move
srm_test::srm_test_sbt::mint_nft(&signer, @receiver_address);
```
- Only the admin can mint.  
- Mints an NFT **directly to the receiver**.  
- Emits a **MintEvent** for tracking.  

### **3️⃣ Get Minted Count**
Check the total number of NFTs minted:
```move
srm_test::srm_test_sbt::get_minted_count(@admin_address);
```

### **4️⃣ Check Remaining Supply**
Check how many NFTs can still be minted:
```move
srm_test::srm_test_sbt::get_remaining_supply(@admin_address);
```

---

## **⚠️ Error Codes**
| Error Code | Meaning |
|------------|---------|
| `1`  | **Not Authorized**: Only the admin can mint NFTs. |
| `2`  | **Collection Not Initialized**: Must initialize before minting. |
| `3`  | **Max Supply Reached**: No more NFTs can be minted. |
| `4`  | **Already Initialized**: Collection is already set up. |

