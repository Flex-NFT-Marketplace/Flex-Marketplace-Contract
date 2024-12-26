pub mod UintSet {
    use core::starknet::storage::{
        Map, StoragePath, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, Mutable
    };

    #[starknet::storage_node]
    pub struct UintSet {
        pub indices: Map<u256, u32>,
        pub indices_len: u32,
        pub values: Map<u32, u256>,
        pub size: u32
    }

    #[generate_trait]
    pub impl UintSetImpl of UintSetTrait {
        fn add(self: StoragePath<Mutable<UintSet>>, value: u256) {
            if (self.indices.read(value) == 0) {
                let fresh_index: u32 = self.indices_len.read() + 1;
                self.indices.write(value, fresh_index);
                self.indices_len.write(fresh_index);
                self.values.write(fresh_index, value);
                self.size.write(self.size.read() + 1);
            }
        }
        fn remove(self: StoragePath<Mutable<UintSet>>, value: u256) {
            if (self.indices.read(value) != 0) {
                self.values.write(self.indices.read(value), 0);
                self.indices.write(value, 0);
                self.indices_len.write(self.indices_len.read() - 1);
                self.size.write(self.size.read() - 1);
            }
        }
    }
}
