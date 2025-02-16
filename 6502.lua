local opcodes = {
  -- ADC (Add with Carry)
  -- ADC Immediate
  [0x69] = function() end,
  -- ADC Zero Page
  [0x65] = function() end,
  -- ADC Zero Page,X
  [0x75] = function() end,
  -- ADC Absolute
  [0x6D] = function() end,
  -- ADC Absolute,X
  [0x7D] = function() end,
  -- ADC Absolute,Y
  [0x79] = function() end,
  -- ADC (Indirect,X)
  [0x61] = function() end,
  -- ADC (Indirect),Y
  [0x71] = function() end,

  -- AND (Logical AND)
  -- AND Immediate
  [0x29] = function() end,
  -- AND Zero Page
  [0x25] = function() end,
  -- AND Zero Page,X
  [0x35] = function() end,
  -- AND Absolute
  [0x2D] = function() end,
  -- AND Absolute,X
  [0x3D] = function() end,
  -- AND Absolute,Y
  [0x39] = function() end,
  -- AND (Indirect,X)
  [0x21] = function() end,
  -- AND (Indirect),Y
  [0x31] = function() end,

  -- ASL (Arithmetic Shift Left)
  -- ASL Accumulator
  [0x0A] = function() end,
  -- ASL Zero Page
  [0x06] = function() end,
  -- ASL Zero Page,X
  [0x16] = function() end,
  -- ASL Absolute
  [0x0E] = function() end,
  -- ASL Absolute,X
  [0x1E] = function() end,

  -- Branch Instructions
  -- BCC Relative
  [0x90] = function() end,
  -- BCS Relative
  [0xB0] = function() end,
  -- BEQ Relative
  [0xF0] = function() end,
  -- BMI Relative
  [0x30] = function() end,
  -- BNE Relative
  [0xD0] = function() end,
  -- BPL Relative
  [0x10] = function() end,
  -- BVC Relative
  [0x50] = function() end,
  -- BVS Relative
  [0x70] = function() end,

  -- BIT (Bit Test)
  -- BIT Zero Page
  [0x24] = function() end,
  -- BIT Absolute
  [0x2C] = function() end,

  -- BRK (Force Interrupt)
  -- BRK Implied
  [0x00] = function() end,

  -- Flag Instructions
  -- CLC Implied
  [0x18] = function() end,
  -- CLD Implied
  [0xD8] = function() end,
  -- CLI Implied
  [0x58] = function() end,
  -- CLV Implied
  [0xB8] = function() end,

  -- CMP (Compare Accumulator)
  -- CMP Immediate
  [0xC9] = function() end,
  -- CMP Zero Page
  [0xC5] = function() end,
  -- CMP Zero Page,X
  [0xD5] = function() end,
  -- CMP Absolute
  [0xCD] = function() end,
  -- CMP Absolute,X
  [0xDD] = function() end,
  -- CMP Absolute,Y
  [0xD9] = function() end,
  -- CMP (Indirect,X)
  [0xC1] = function() end,
  -- CMP (Indirect),Y
  [0xD1] = function() end,

  -- CPX (Compare X Register)
  -- CPX Immediate
  [0xE0] = function() end,
  -- CPX Zero Page
  [0xE4] = function() end,
  -- CPX Absolute
  [0xEC] = function() end,

  -- CPY (Compare Y Register)
  -- CPY Immediate
  [0xC0] = function() end,
  -- CPY Zero Page
  [0xC4] = function() end,
  -- CPY Absolute
  [0xCC] = function() end,

  -- DEC (Decrement Memory)
  -- DEC Zero Page
  [0xC6] = function() end,
  -- DEC Zero Page,X
  [0xD6] = function() end,
  -- DEC Absolute
  [0xCE] = function() end,
  -- DEC Absolute,X
  [0xDE] = function() end,

  -- DEX (Decrement X Register)
  -- DEX Implied
  [0xCA] = function() end,

  -- DEY (Decrement Y Register)
  -- DEY Implied
  [0x88] = function() end,

  -- EOR (Exclusive OR)
  -- EOR Immediate
  [0x49] = function() end,
  -- EOR Zero Page
  [0x45] = function() end,
  -- EOR Zero Page,X
  [0x55] = function() end,
  -- EOR Absolute
  [0x4D] = function() end,
  -- EOR Absolute,X
  [0x5D] = function() end,
  -- EOR Absolute,Y
  [0x59] = function() end,
  -- EOR (Indirect,X)
  [0x41] = function() end,
  -- EOR (Indirect),Y
  [0x51] = function() end,

  -- INC (Increment Memory)
  -- INC Zero Page
  [0xE6] = function() end,
  -- INC Zero Page,X
  [0xF6] = function() end,
  -- INC Absolute
  [0xEE] = function() end,
  -- INC Absolute,X
  [0xFE] = function() end,

  -- INX (Increment X Register)
  -- INX Implied
  [0xE8] = function() end,

  -- INY (Increment Y Register)
  -- INY Implied
  [0xC8] = function() end,

  -- JMP (Jump)
  -- JMP Absolute
  [0x4C] = function() end,
  -- JMP Indirect
  [0x6C] = function() end,

  -- JSR (Jump to Subroutine)
  -- JSR Absolute
  [0x20] = function() end,

  -- LDA (Load Accumulator)
  -- LDA Immediate
  [0xA9] = function() end,
  -- LDA Zero Page
  [0xA5] = function() end,
  -- LDA Zero Page,X
  [0xB5] = function() end,
  -- LDA Absolute
  [0xAD] = function() end,
  -- LDA Absolute,X
  [0xBD] = function() end,
  -- LDA Absolute,Y
  [0xB9] = function() end,
  -- LDA (Indirect,X)
  [0xA1] = function() end,
  -- LDA (Indirect),Y
  [0xB1] = function() end,

  -- LDX (Load X Register)
  -- LDX Immediate
  [0xA2] = function() end,
  -- LDX Zero Page
  [0xA6] = function() end,
  -- LDX Zero Page,Y
  [0xB6] = function() end,
  -- LDX Absolute
  [0xAE] = function() end,
  -- LDX Absolute,Y
  [0xBE] = function() end,

  -- LDY (Load Y Register)
  -- LDY Immediate
  [0xA0] = function() end,
  -- LDY Zero Page
  [0xA4] = function() end,
  -- LDY Zero Page,X
  [0xB4] = function() end,
  -- LDY Absolute
  [0xAC] = function() end,
  -- LDY Absolute,X
  [0xBC] = function() end,

  -- LSR (Logical Shift Right)
  -- LSR Accumulator
  [0x4A] = function() end,
  -- LSR Zero Page
  [0x46] = function() end,
  -- LSR Zero Page,X
  [0x56] = function() end,
  -- LSR Absolute
  [0x4E] = function() end,
  -- LSR Absolute,X
  [0x5E] = function() end,

  -- NOP (No Operation)
  -- NOP Implied
  [0xEA] = function() end,

  -- ORA (Logical Inclusive OR)
  -- ORA Immediate
  [0x09] = function() end,
  -- ORA Zero Page
  [0x05] = function() end,
  -- ORA Zero Page,X
  [0x15] = function() end,
  -- ORA Absolute
  [0x0D] = function() end,
  -- ORA Absolute,X
  [0x1D] = function() end,
  -- ORA Absolute,Y
  [0x19] = function() end,
  -- ORA (Indirect,X)
  [0x01] = function() end,
  -- ORA (Indirect),Y
  [0x11] = function() end,

  -- PHA (Push Accumulator)
  -- PHA Implied
  [0x48] = function() end,

  -- PHP (Push Processor Status)
  -- PHP Implied
  [0x08] = function() end,

  -- PLA (Pull Accumulator)
  -- PLA Implied
  [0x68] = function() end,

  -- PLP (Pull Processor Status)
  -- PLP Implied
  [0x28] = function() end,

  -- ROL (Rotate Left)
  -- ROL Accumulator
  [0x2A] = function() end,
  -- ROL Zero Page
  [0x26] = function() end,
  -- ROL Zero Page,X
  [0x36] = function() end,
  -- ROL Absolute
  [0x2E] = function() end,
  -- ROL Absolute,X
  [0x3E] = function() end,

  -- ROR (Rotate Right)
  -- ROR Accumulator
  [0x6A] = function() end,
  -- ROR Zero Page
  [0x66] = function() end,
  -- ROR Zero Page,X
  [0x76] = function() end,
  -- ROR Absolute
  [0x6E] = function() end,
  -- ROR Absolute,X
  [0x7E] = function() end,

  -- RTI (Return from Interrupt)
  -- RTI Implied
  [0x40] = function() end,

  -- RTS (Return from Subroutine)
  -- RTS Implied
  [0x60] = function() end,

  -- SBC (Subtract with Carry)
  -- SBC Immediate
  [0xE9] = function() end,
  -- SBC Zero Page
  [0xE5] = function() end,
  -- SBC Zero Page,X
  [0xF5] = function() end,
  -- SBC Absolute
  [0xED] = function() end,
  -- SBC Absolute,X
  [0xFD] = function() end,
  -- SBC Absolute,Y
  [0xF9] = function() end,
  -- SBC (Indirect,X)
  [0xE1] = function() end,
  -- SBC (Indirect),Y
  [0xF1] = function() end,

  -- Set Carry, Decimal and Interrupt flags
  -- SEC Implied
  [0x38] = function() end,
  -- SED Implied
  [0xF8] = function() end,
  -- SEI Implied
  [0x78] = function() end,

  -- STA (Store Accumulator)
  -- STA Zero Page
  [0x85] = function() end,
  -- STA Zero Page,X
  [0x95] = function() end,
  -- STA Absolute
  [0x8D] = function() end,
  -- STA Absolute,X
  [0x9D] = function() end,
  -- STA Absolute,Y
  [0x99] = function() end,
  -- STA (Indirect,X)
  [0x81] = function() end,
  -- STA (Indirect),Y
  [0x91] = function() end,

  -- STX (Store X Register)
  -- STX Zero Page
  [0x86] = function() end,
  -- STX Zero Page,Y
  [0x96] = function() end,
  -- STX Absolute
  [0x8E] = function() end,

  -- STY (Store Y Register)
  -- STY Zero Page
  [0x84] = function() end,
  -- STY Zero Page,X
  [0x94] = function() end,
  -- STY Absolute
  [0x8C] = function() end,
}

local MOS6502 = {}
MOS6502.__index = MOS6502

function MOS6502.new()
  local self  = setmetatable({}, MOS6502)
  self.A      = 0      -- Accumulator
  self.X      = 0      -- X Register
  self.Y      = 0      -- Y Register
  self.SP     = 0xFD   -- Stack Pointer
  self.PC     = 0x0000 -- Program Counter
  self.P      = 0x24   -- Processor Status
  self.cycles = 0      -- Cycle count

  self.memory = {}
  for i = 0, 0xFFFF do
    self.memory[i] = 0
  end
  return self
end

function MOS6502:read(addr)
  return self.memory[addr]
end

function MOS6502:write(addr, value)
  self.memory[addr] = value & 0xFF
end

function MOS6502:fetch()
  local mem  = self.memory
  local pc   = self.PC
  local byte = mem[pc]
  self.PC    = (pc + 1) & 0xFFFF
  return byte
end

function MOS6502:flag(value)
  local P = self.P
  if value == 0 then
    P = P | 0x02
  else
    P = P & 0xFD
  end
  if (value & 0x80) ~= 0 then
    P = P | 0x80
  else
    P = P & 0x7F
  end
  self.P = P
end

function MOS6502:step()
  local opcode = self:fetch()
  local operation = opcodes[opcode]
  if operation then
    operation(self)
  end
end

function MOS6502:push(val)
  local sp = self.SP
  self:write(0x0100 + sp, val)
  self.SP = (sp - 1) & 0xFF
end

function MOS6502:pop()
  self.SP = (self.SP + 1) & 0xFF
  return self:read(0x0100 + self.SP)
end

function MOS6502:reset()
  local mem = self.memory
  self.PC = mem[0xFFFC] + (mem[0xFFFD] << 8)
  self.SP = 0xFD
  self.P = 0x24
end

function MOS6502:irq()
  local p = self.P
  if (p & 0x04) == 0 then
    local pc = self.PC
    self:push((pc >> 8) & 0xFF)
    self:push(pc & 0xFF)
    self:push((p & 0xEF) | 0x20)
    self.P = p | 0x04
    local mem = self.memory
    self.PC = mem[0xFFFE] + (mem[0xFFFF] << 8)
    self.cycles = self.cycles + 7
  end
end

function MOS6502:nmi()
  local p = self.P
  local pc = self.PC
  self:push((pc >> 8) & 0xFF)
  self:push(pc & 0xFF)
  self:push((p & 0xEF) | 0x20)
  self.P = p | 0x04
  local mem = self.memory
  self.PC = mem[0xFFFA] + (mem[0xFFFB] << 8)
  self.cycles = self.cycles + 8
end
