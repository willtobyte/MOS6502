local opcodes = {
  -- ADC (Add with Carry)
  -- ADC Immediate
  [0x69] = function(cpu)
    return 2
  end,
  -- ADC Zero Page
  [0x65] = function(cpu)
    return 3
  end,
  -- ADC Zero Page,X
  [0x75] = function(cpu)
    return 4
  end,
  -- ADC Absolute
  [0x6D] = function(cpu)
    return 4
  end,
  -- ADC Absolute,X
  [0x7D] = function(cpu)
    return 4
  end,
  -- ADC Absolute,Y
  [0x79] = function(cpu)
    return 4
  end,
  -- ADC (Indirect,X)
  [0x61] = function(cpu)
    return 6
  end,
  -- ADC (Indirect),Y
  [0x71] = function(cpu)
    return 5
  end,

  -- AND (Logical AND)
  -- AND Immediate
  [0x29] = function(cpu)
    return 2
  end,
  -- AND Zero Page
  [0x25] = function(cpu)
    return 3
  end,
  -- AND Zero Page,X
  [0x35] = function(cpu)
    return 4
  end,
  -- AND Absolute
  [0x2D] = function(cpu)
    return 4
  end,
  -- AND Absolute,X
  [0x3D] = function(cpu)
    return 4
  end,
  -- AND Absolute,Y
  [0x39] = function(cpu)
    return 4
  end,
  -- AND (Indirect,X)
  [0x21] = function(cpu)
    return 6
  end,
  -- AND (Indirect),Y
  [0x31] = function(cpu)
    return 5
  end,

  -- ASL (Arithmetic Shift Left)
  -- ASL Accumulator
  [0x0A] = function(cpu)
    return 2
  end,
  -- ASL Zero Page
  [0x06] = function(cpu)
    return 5
  end,
  -- ASL Zero Page,X
  [0x16] = function(cpu)
    return 6
  end,
  -- ASL Absolute
  [0x0E] = function(cpu)
    return 6
  end,
  -- ASL Absolute,X
  [0x1E] = function(cpu)
    return 7
  end,

  -- Branch Instructions
  -- BCC Relative
  [0x90] = function(cpu)
    return 2
  end,
  -- BCS Relative
  [0xB0] = function(cpu)
    return 2
  end,
  -- BEQ Relative
  [0xF0] = function(cpu)
    return 2
  end,
  -- BMI Relative
  [0x30] = function(cpu)
    return 2
  end,
  -- BNE Relative
  [0xD0] = function(cpu)
    return 2
  end,
  -- BPL Relative
  [0x10] = function(cpu)
    return 2
  end,
  -- BVC Relative
  [0x50] = function(cpu)
    return 2
  end,
  -- BVS Relative
  [0x70] = function(cpu)
    return 2
  end,

  -- BIT (Bit Test)
  -- BIT Zero Page
  [0x24] = function(cpu)
    return 3
  end,
  -- BIT Absolute
  [0x2C] = function(cpu)
    return 4
  end,

  -- BRK (Force Interrupt)
  -- BRK Implied
  [0x00] = function(cpu)
    return 7
  end,

  -- Flag Instructions
  -- CLC Implied
  [0x18] = function(cpu)
    return 2
  end,
  -- CLD Implied
  [0xD8] = function(cpu)
    return 2
  end,
  -- CLI Implied
  [0x58] = function(cpu)
    return 2
  end,
  -- CLV Implied
  [0xB8] = function(cpu)
    return 2
  end,

  -- CMP (Compare Accumulator)
  -- CMP Immediate
  [0xC9] = function(cpu)
    return 2
  end,
  -- CMP Zero Page
  [0xC5] = function(cpu)
    return 3
  end,
  -- CMP Zero Page,X
  [0xD5] = function(cpu)
    return 4
  end,
  -- CMP Absolute
  [0xCD] = function(cpu)
    return 4
  end,
  -- CMP Absolute,X
  [0xDD] = function(cpu)
    return 4
  end,
  -- CMP Absolute,Y
  [0xD9] = function(cpu)
    return 4
  end,
  -- CMP (Indirect,X)
  [0xC1] = function(cpu)
    return 6
  end,
  -- CMP (Indirect),Y
  [0xD1] = function(cpu)
    return 5
  end,

  -- CPX (Compare X Register)
  -- CPX Immediate
  [0xE0] = function(cpu)
    return 2
  end,
  -- CPX Zero Page
  [0xE4] = function(cpu)
    return 3
  end,
  -- CPX Absolute
  [0xEC] = function(cpu)
    return 4
  end,

  -- CPY (Compare Y Register)
  -- CPY Immediate
  [0xC0] = function(cpu)
    return 2
  end,
  -- CPY Zero Page
  [0xC4] = function(cpu)
    return 3
  end,
  -- CPY Absolute
  [0xCC] = function(cpu)
    return 4
  end,

  -- DEC (Decrement Memory)
  -- DEC Zero Page
  [0xC6] = function(cpu)
    return 5
  end,
  -- DEC Zero Page,X
  [0xD6] = function(cpu)
    return 6
  end,
  -- DEC Absolute
  [0xCE] = function(cpu)
    return 6
  end,
  -- DEC Absolute,X
  [0xDE] = function(cpu)
    return 7
  end,

  -- DEX (Decrement X Register)
  -- DEX Implied
  [0xCA] = function(cpu)
    return 2
  end,

  -- DEY (Decrement Y Register)
  -- DEY Implied
  [0x88] = function(cpu)
    return 2
  end,

  -- EOR (Exclusive OR)
  -- EOR Immediate
  [0x49] = function(cpu)
    return 2
  end,
  -- EOR Zero Page
  [0x45] = function(cpu)
    return 3
  end,
  -- EOR Zero Page,X
  [0x55] = function(cpu)
    return 4
  end,
  -- EOR Absolute
  [0x4D] = function(cpu)
    return 4
  end,
  -- EOR Absolute,X
  [0x5D] = function(cpu)
    return 4
  end,
  -- EOR Absolute,Y
  [0x59] = function(cpu)
    return 4
  end,
  -- EOR (Indirect,X)
  [0x41] = function(cpu)
    return 6
  end,
  -- EOR (Indirect),Y
  [0x51] = function(cpu)
    return 5
  end,

  -- INC (Increment Memory)
  -- INC Zero Page
  [0xE6] = function(cpu)
    return 5
  end,
  -- INC Zero Page,X
  [0xF6] = function(cpu)
    return 6
  end,
  -- INC Absolute
  [0xEE] = function(cpu)
    return 6
  end,
  -- INC Absolute,X
  [0xFE] = function(cpu)
    return 7
  end,

  -- INX (Increment X Register)
  -- INX Implied
  [0xE8] = function(cpu)
    return 2
  end,

  -- INY (Increment Y Register)
  -- INY Implied
  [0xC8] = function(cpu)
    return 2
  end,

  -- JMP (Jump)
  -- JMP Absolute
  [0x4C] = function(cpu)
    return 3
  end,
  -- JMP Indirect
  [0x6C] = function(cpu)
    return 5
  end,

  -- JSR (Jump to Subroutine)
  -- JSR Absolute
  [0x20] = function(cpu)
    return 6
  end,

  -- LDA (Load Accumulator)
  -- LDA Immediate
  [0xA9] = function(cpu)
    return 2
  end,
  -- LDA Zero Page
  [0xA5] = function(cpu)
    return 3
  end,
  -- LDA Zero Page,X
  [0xB5] = function(cpu)
    return 4
  end,
  -- LDA Absolute
  [0xAD] = function(cpu)
    return 4
  end,
  -- LDA Absolute,X
  [0xBD] = function(cpu)
    return 4
  end,
  -- LDA Absolute,Y
  [0xB9] = function(cpu)
    return 4
  end,
  -- LDA (Indirect,X)
  [0xA1] = function(cpu)
    return 6
  end,
  -- LDA (Indirect),Y
  [0xB1] = function(cpu)
    return 5
  end,

  -- LDX (Load X Register)
  -- LDX Immediate
  [0xA2] = function(cpu)
    return 2
  end,
  -- LDX Zero Page
  [0xA6] = function(cpu)
    return 3
  end,
  -- LDX Zero Page,Y
  [0xB6] = function(cpu)
    return 4
  end,
  -- LDX Absolute
  [0xAE] = function(cpu)
    return 4
  end,
  -- LDX Absolute,Y
  [0xBE] = function(cpu)
    return 4
  end,

  -- LDY (Load Y Register)
  -- LDY Immediate
  [0xA0] = function(cpu)
    return 2
  end,
  -- LDY Zero Page
  [0xA4] = function(cpu)
    return 3
  end,
  -- LDY Zero Page,X
  [0xB4] = function(cpu)
    return 4
  end,
  -- LDY Absolute
  [0xAC] = function(cpu)
    return 4
  end,
  -- LDY Absolute,X
  [0xBC] = function(cpu)
    return 4
  end,

  -- LSR (Logical Shift Right)
  -- LSR Accumulator
  [0x4A] = function(cpu)
    return 2
  end,
  -- LSR Zero Page
  [0x46] = function(cpu)
    return 5
  end,
  -- LSR Zero Page,X
  [0x56] = function(cpu)
    return 6
  end,
  -- LSR Absolute
  [0x4E] = function(cpu)
    return 6
  end,
  -- LSR Absolute,X
  [0x5E] = function(cpu)
    return 7
  end,

  -- NOP (No Operation)
  -- NOP Implied
  [0xEA] = function(cpu)
    return 2
  end,

  -- ORA (Logical Inclusive OR)
  -- ORA Immediate
  [0x09] = function(cpu)
    return 2
  end,
  -- ORA Zero Page
  [0x05] = function(cpu)
    return 3
  end,
  -- ORA Zero Page,X
  [0x15] = function(cpu)
    return 4
  end,
  -- ORA Absolute
  [0x0D] = function(cpu)
    return 4
  end,
  -- ORA Absolute,X
  [0x1D] = function(cpu)
    return 4
  end,
  -- ORA Absolute,Y
  [0x19] = function(cpu)
    return 4
  end,
  -- ORA (Indirect,X)
  [0x01] = function(cpu)
    return 6
  end,
  -- ORA (Indirect),Y
  [0x11] = function(cpu)
    return 5
  end,

  -- PHA (Push Accumulator)
  -- PHA Implied
  [0x48] = function(cpu)
    return 3
  end,

  -- PHP (Push Processor Status)
  -- PHP Implied
  [0x08] = function(cpu)
    return 3
  end,

  -- PLA (Pull Accumulator)
  -- PLA Implied
  [0x68] = function(cpu)
    return 4
  end,

  -- PLP (Pull Processor Status)
  -- PLP Implied
  [0x28] = function(cpu)
    return 4
  end,

  -- ROL (Rotate Left)
  -- ROL Accumulator
  [0x2A] = function(cpu)
    return 2
  end,
  -- ROL Zero Page
  [0x26] = function(cpu)
    return 5
  end,
  -- ROL Zero Page,X
  [0x36] = function(cpu)
    return 6
  end,
  -- ROL Absolute
  [0x2E] = function(cpu)
    return 6
  end,
  -- ROL Absolute,X
  [0x3E] = function(cpu)
    return 7
  end,

  -- ROR (Rotate Right)
  -- ROR Accumulator
  [0x6A] = function(cpu)
    return 2
  end,
  -- ROR Zero Page
  [0x66] = function(cpu)
    return 5
  end,
  -- ROR Zero Page,X
  [0x76] = function(cpu)
    return 6
  end,
  -- ROR Absolute
  [0x6E] = function(cpu)
    return 6
  end,
  -- ROR Absolute,X
  [0x7E] = function(cpu)
    return 7
  end,

  -- RTI (Return from Interrupt)
  -- RTI Implied
  [0x40] = function(cpu)
    return 6
  end,

  -- RTS (Return from Subroutine)
  -- RTS Implied
  [0x60] = function(cpu)
    return 6
  end,

  -- SBC (Subtract with Carry)
  -- SBC Immediate
  [0xE9] = function(cpu)
    return 2
  end,
  -- SBC Zero Page
  [0xE5] = function(cpu)
    return 3
  end,
  -- SBC Zero Page,X
  [0xF5] = function(cpu)
    return 4
  end,
  -- SBC Absolute
  [0xED] = function(cpu)
    return 4
  end,
  -- SBC Absolute,X
  [0xFD] = function(cpu)
    return 4
  end,
  -- SBC Absolute,Y
  [0xF9] = function(cpu)
    return 4
  end,
  -- SBC (Indirect,X)
  [0xE1] = function(cpu)
    return 6
  end,
  -- SBC (Indirect),Y
  [0xF1] = function(cpu)
    return 5
  end,

  -- Set Carry, Decimal and Interrupt flags
  -- SEC Implied
  [0x38] = function(cpu)
    return 2
  end,
  -- SED Implied
  [0xF8] = function(cpu)
    return 2
  end,
  -- SEI Implied
  [0x78] = function(cpu)
    return 2
  end,

  -- STA (Store Accumulator)
  -- STA Zero Page
  [0x85] = function(cpu)
    return 3
  end,
  -- STA Zero Page,X
  [0x95] = function(cpu)
    return 4
  end,
  -- STA Absolute
  [0x8D] = function(cpu)
    return 4
  end,
  -- STA Absolute,X
  [0x9D] = function(cpu)
    return 5
  end,
  -- STA Absolute,Y
  [0x99] = function(cpu)
    return 5
  end,
  -- STA (Indirect,X)
  [0x81] = function(cpu)
    return 6
  end,
  -- STA (Indirect),Y
  [0x91] = function(cpu)
    return 6
  end,

  -- STX (Store X Register)
  -- STX Zero Page
  [0x86] = function(cpu)
    return 3
  end,
  -- STX Zero Page,Y
  [0x96] = function(cpu)
    return 4
  end,
  -- STX Absolute
  [0x8E] = function(cpu)
    return 4
  end,

  -- STY (Store Y Register)
  -- STY Zero Page
  [0x84] = function(cpu)
    return 3
  end,
  -- STY Zero Page,X
  [0x94] = function(cpu)
    return 4
  end,
  -- STY Absolute
  [0x8C] = function(cpu)
    return 4
  end,
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

function MOS6502:znupdate(value)
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
  local op = opcodes[opcode]
  if op then
    self.cycles = self.cycles + op(self)
    return
  end

  error(string.format("opcode 0x%02X not implemented.", opcode))
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
