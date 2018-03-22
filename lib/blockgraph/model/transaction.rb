module BlockGraph
  module Model
    class Transaction < ActiveNodeBase

      property :txid
      property :version, type: Integer
      property :marker, type: Integer
      property :flag, type: Integer
      property :lock_time

      has_one :out, :block, type: :block, model_class: 'BlockGraph::Model::BlockHeader'
      has_many :in, :inputs, origin: :transaction, model_class: 'BlockGraph::Model::TxIn', dependent: :destroy
      has_many :in, :outputs, origin: :transaction, model_class: 'BlockGraph::Model::TxOut', dependent: :destroy

      validates :txid, :presence => true
      validates :version, :presence => true
      validates :lock_time, :presence => true

      scope :with_txid, ->(txid){where(txid: txid)}

      MARKER = 0x00
      FLAG = 0x01

      def self.create_from_tx(tx)
        transaction = new
        transaction.txid = tx.txid
        transaction.version = tx.version
        transaction.marker = tx.marker
        transaction.flag = tx.flag
        transaction.lock_time = tx.lock_time
        transaction.save!
        tx.inputs.each do |i|
          transaction.inputs << BlockGraph::Model::TxIn.create_from_tx(i)
        end
        tx.outputs.each_with_index do |o, n|
          transaction.outputs << BlockGraph::Model::TxOut.create_from_tx(o, n)
        end
        transaction.save!
        transaction
      end

      def to_payload
        witness? ? serialize_witness_format : serialize_old_format
      end

      def witness?
        inputs = self.inputs.to_a
        !inputs.find { |i| !i.script_witness.nil? }.nil?
      end

      # serialize tx with old tx format
      def serialize_old_format
        buf = [self.version].pack('V')
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.order(vout: :asc).map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.order(n: :asc).map(&:to_payload).join
        buf << [self.lock_time].pack('V')
        buf
      end

      # serialize tx with segwit tx format
      # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki
      def serialize_witness_format
        buf = [self.version, MARKER, FLAG].pack('Vcc')
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.map(&:to_payload).join
        buf << witness_payload << [self.lock_time].pack('V')
        buf
      end

      def witness_payload
        self.inputs.map { |i| i.script_witness.to_payload }.join
      end

    end
  end
end