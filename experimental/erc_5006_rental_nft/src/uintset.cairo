pub mod UintSet {
    use core::starknet::storage::{
        Map, 
        StoragePath, 
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        Mutable
    };

    #[starknet::storage_node]
    pub struct UintSet {
        indices: Map<u256,u32>,
        indices_len: u32,
        values: Map<u32, u256>,
        size: u32
    }
    
    #[generate_trait]
    pub impl UintSetImpl of UintSetTrait {
        fn add(self: StoragePath<Mutable<UintSet>>, value: u256) {
            if(self.indices.read(value) == 0) {
                let fresh_index: u32 = self.indices_len.read();
                self.indices.write(value, fresh_index);
                self.indices_len.write(fresh_index + 1);
                self.values.write(fresh_index, value);
                self.size.write(self.size.read()+1);
            }
        }
        fn remove(self: StoragePath<Mutable<UintSet>>, value: u256) {
            if(self.indices.read(value) != 0) {
                self.indices.write(value,0);
                self.size.write(self.size.read()-1);
            }
        }
        fn contains(self: StoragePath<UintSet>, value: u256) -> bool {
            let mut found = false;
            // since we don't delete we must pay for # of total insertions
            // and not current size
            for index in 0..self.indices_len.read() {
                if(self.values.read(index) == value) {
                    found = true;
                    break;
                }
            };
            found
        }
    }
}