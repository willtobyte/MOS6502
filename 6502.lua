local opcodes = {
  -- ADC (Add with Carry)
  -- ADC Immediate
  [0x69] = { cycles = 2, exec = function(cpu) end },
  -- ADC Zero Page
  [0x65] = { cycles = 3, exec = function(cpu) end },
  -- ADC Zero Page,X
  [0x75] = { cycles = 4, exec = function(cpu) end },
  -- ADC Absolute
  [0x6D] = { cycles = 4, exec = function(cpu) end },
  -- ADC Absolute,X
  [0x7D] = { cycles = 4, exec = function(cpu) end },
  -- ADC Absolute,Y
  [0x79] = { cycles = 4, exec = function(cpu) end },
  -- ADC (Indirect,X)
  [0x61] = { cycles = 6, exec = function(cpu) end },
  -- ADC (Indirect),Y
  [0x71] = { cycles = 5, exec = function(cpu) end },

  -- AND (Logical AND)
  -- AND Immediate
  [0x29] = { cycles = 2, exec = function(cpu) end },
  -- AND Zero Page
  [0x25] = { cycles = 3, exec = function(cpu) end },
  -- AND Zero Page,X
  [0x35] = { cycles = 4, exec = function(cpu) end },
  -- AND Absolute
  [0x2D] = { cycles = 4, exec = function(cpu) end },
  -- AND Absolute,X
  [0x3D] = { cycles = 4, exec = function(cpu) end },
  -- AND Absolute,Y
  [0x39] = { cycles = 4, exec = function(cpu) end },
  -- AND (Indirect,X)
  [0x21] = { cycles = 6, exec = function(cpu) end },
  -- AND (Indirect),Y
  [0x31] = { cycles = 5, exec = function(cpu) end },

  -- ASL (Arithmetic Shift Left)
  -- ASL Accumulator
  [0x0A] = { cycles = 2, exec = function(cpu) end },
  -- ASL Zero Page
  [0x06] = { cycles = 5, exec = function(cpu) end },
  -- ASL Zero Page,X
  [0x16] = { cycles = 6, exec = function(cpu) end },
  -- ASL Absolute
  [0x0E] = { cycles = 6, exec = function(cpu) end },
  -- ASL Absolute,X
  [0x1E] = { cycles = 7, exec = function(cpu) end },

  -- Branch Instructions
  -- BCC Relative
  [0x90] = { cycles = 2, exec = function(cpu) end },
  -- BCS Relative
  [0xB0] = { cycles = 2, exec = function(cpu) end },
  -- BEQ Relative
  [0xF0] = { cycles = 2, exec = function(cpu) end },
  -- BMI Relative
  [0x30] = { cycles = 2, exec = function(cpu) end },
  -- BNE Relative
  [0xD0] = { cycles = 2, exec = function(cpu) end },
  -- BPL Relative
  [0x10] = { cycles = 2, exec = function(cpu) end },
  -- BVC Relative
  [0x50] = { cycles = 2, exec = function(cpu) end },
  -- BVS Relative
  [0x70] = { cycles = 2, exec = function(cpu) end },

  -- BIT (Bit Test)
  -- BIT Zero Page
  [0x24] = { cycles = 3, exec = function(cpu) end },
  -- BIT Absolute
  [0x2C] = { cycles = 4, exec = function(cpu) end },

  -- BRK (Force Interrupt)
  -- BRK Implied
  [0x00] = { cycles = 7, exec = function(cpu) end },

  -- Flag Instructions
  -- CLC Implied
  [0x18] = { cycles = 2, exec = function(cpu) end },
  -- CLD Implied
  [0xD8] = { cycles = 2, exec = function(cpu) end },
  -- CLI Implied
  [0x58] = { cycles = 2, exec = function(cpu) end },
  -- CLV Implied
  [0xB8] = { cycles = 2, exec = function(cpu) end },

  -- CMP (Compare Accumulator)
  -- CMP Immediate
  [0xC9] = { cycles = 2, exec = function(cpu) end },
  -- CMP Zero Page
  [0xC5] = { cycles = 3, exec = function(cpu) end },
  -- CMP Zero Page,X
  [0xD5] = { cycles = 4, exec = function(cpu) end },
  -- CMP Absolute
  [0xCD] = { cycles = 4, exec = function(cpu) end },
  -- CMP Absolute,X
  [0xDD] = { cycles = 4, exec = function(cpu) end },
  -- CMP Absolute,Y
  [0xD9] = { cycles = 4, exec = function(cpu) end },
  -- CMP (Indirect,X)
  [0xC1] = { cycles = 6, exec = function(cpu) end },
  -- CMP (Indirect),Y
  [0xD1] = { cycles = 5, exec = function(cpu) end },

  -- CPX (Compare X Register)
  -- CPX Immediate
  [0xE0] = { cycles = 2, exec = function(cpu) end },
  -- CPX Zero Page
  [0xE4] = { cycles = 3, exec = function(cpu) end },
  -- CPX Absolute
  [0xEC] = { cycles = 4, exec = function(cpu) end },

  -- CPY (Compare Y Register)
  -- CPY Immediate
  [0xC0] = { cycles = 2, exec = function(cpu) end },
  -- CPY Zero Page
  [0xC4] = { cycles = 3, exec = function(cpu) end },
  -- CPY Absolute
  [0xCC] = { cycles = 4, exec = function(cpu) end },

  -- DEC (Decrement Memory)
  -- DEC Zero Page
  [0xC6] = { cycles = 5, exec = function(cpu) end },
  -- DEC Zero Page,X
  [0xD6] = { cycles = 6, exec = function(cpu) end },
  -- DEC Absolute
  [0xCE] = { cycles = 6, exec = function(cpu) end },
  -- DEC Absolute,X
  [0xDE] = { cycles = 7, exec = function(cpu) end },

  -- DEX (Decrement X Register)
  -- DEX Implied
  [0xCA] = { cycles = 2, exec = function(cpu) end },

  -- DEY (Decrement Y Register)
  -- DEY Implied
  [0x88] = { cycles = 2, exec = function(cpu) end },

  -- EOR (Exclusive OR)
  -- EOR Immediate
  [0x49] = { cycles = 2, exec = function(cpu) end },
  -- EOR Zero Page
  [0x45] = { cycles = 3, exec = function(cpu) end },
  -- EOR Zero Page,X
  [0x55] = { cycles = 4, exec = function(cpu) end },
  -- EOR Absolute
  [0x4D] = { cycles = 4, exec = function(cpu) end },
  -- EOR Absolute,X
  [0x5D] = { cycles = 4, exec = function(cpu) end },
  -- EOR Absolute,Y
  [0x59] = { cycles = 4, exec = function(cpu) end },
  -- EOR (Indirect,X)
  [0x41] = { cycles = 6, exec = function(cpu) end },
  -- EOR (Indirect),Y
  [0x51] = { cycles = 5, exec = function(cpu) end },

  -- INC (Increment Memory)
  -- INC Zero Page
  [0xE6] = { cycles = 5, exec = function(cpu) end },
  -- INC Zero Page,X
  [0xF6] = { cycles = 6, exec = function(cpu) end },
  -- INC Absolute
  [0xEE] = { cycles = 6, exec = function(cpu) end },
  -- INC Absolute,X
  [0xFE] = { cycles = 7, exec = function(cpu) end },

  -- INX (Increment X Register)
  -- INX Implied
  [0xE8] = { cycles = 2, exec = function(cpu) end },

  -- INY (Increment Y Register)
  -- INY Implied
  [0xC8] = { cycles = 2, exec = function(cpu) end },

  -- JMP (Jump)
  -- JMP Absolute
  [0x4C] = { cycles = 3, exec = function(cpu) end },
  -- JMP Indirect
  [0x6C] = { cycles = 5, exec = function(cpu) end },

  -- JSR (Jump to Subroutine)
  -- JSR Absolute
  [0x20] = { cycles = 6, exec = function(cpu) end },

  -- LDA (Load Accumulator)
  -- LDA Immediate
  [0xA9] = { cycles = 2, exec = function(cpu) end },
  -- LDA Zero Page
  [0xA5] = { cycles = 3, exec = function(cpu) end },
  -- LDA Zero Page,X
  [0xB5] = { cycles = 4, exec = function(cpu) end },
  -- LDA Absolute
  [0xAD] = { cycles = 4, exec = function(cpu) end },
  -- LDA Absolute,X
  [0xBD] = { cycles = 4, exec = function(cpu) end },
  -- LDA Absolute,Y
  [0xB9] = { cycles = 4, exec = function(cpu) end },
  -- LDA (Indirect,X)
  [0xA1] = { cycles = 6, exec = function(cpu) end },
  -- LDA (Indirect),Y
  [0xB1] = { cycles = 5, exec = function(cpu) end },

  -- LDX (Load X Register)
  -- LDX Immediate
  [0xA2] = { cycles = 2, exec = function(cpu) end },
  -- LDX Zero Page
  [0xA6] = { cycles = 3, exec = function(cpu) end },
  -- LDX Zero Page,Y
  [0xB6] = { cycles = 4, exec = function(cpu) end },
  -- LDX Absolute
  [0xAE] = { cycles = 4, exec = function(cpu) end },
  -- LDX Absolute,Y
  [0xBE] = { cycles = 4, exec = function(cpu) end },

  -- LDY (Load Y Register)
  -- LDY Immediate
  [0xA0] = { cycles = 2, exec = function(cpu) end },
  -- LDY Zero Page
  [0xA4] = { cycles = 3, exec = function(cpu) end },
  -- LDY Zero Page,X
  [0xB4] = { cycles = 4, exec = function(cpu) end },
  -- LDY Absolute
  [0xAC] = { cycles = 4, exec = function(cpu) end },
  -- LDY Absolute,X
  [0xBC] = { cycles = 4, exec = function(cpu) end },

  -- LSR (Logical Shift Right)
  -- LSR Accumulator
  [0x4A] = { cycles = 2, exec = function(cpu) end },
  -- LSR Zero Page
  [0x46] = { cycles = 5, exec = function(cpu) end },
  -- LSR Zero Page,X
  [0x56] = { cycles = 6, exec = function(cpu) end },
  -- LSR Absolute
  [0x4E] = { cycles = 6, exec = function(cpu) end },
  -- LSR Absolute,X
  [0x5E] = { cycles = 7, exec = function(cpu) end },

  -- NOP (No Operation)
  -- NOP Implied
  [0xEA] = { cycles = 2, exec = function(cpu) end },

  -- ORA (Logical Inclusive OR)
  -- ORA Immediate
  [0x09] = { cycles = 2, exec = function(cpu) end },
  -- ORA Zero Page
  [0x05] = { cycles = 3, exec = function(cpu) end },
  -- ORA Zero Page,X
  [0x15] = { cycles = 4, exec = function(cpu) end },
  -- ORA Absolute
  [0x0D] = { cycles = 4, exec = function(cpu) end },
  -- ORA Absolute,X
  [0x1D] = { cycles = 4, exec = function(cpu) end },
  -- ORA Absolute,Y
  [0x19] = { cycles = 4, exec = function(cpu) end },
  -- ORA (Indirect,X)
  [0x01] = { cycles = 6, exec = function(cpu) end },
  -- ORA (Indirect),Y
  [0x11] = { cycles = 5, exec = function(cpu) end },

  -- PHA (Push Accumulator)
  -- PHA Implied
  [0x48] = { cycles = 3, exec = function(cpu) end },

  -- PHP (Push Processor Status)
  -- PHP Implied
  [0x08] = { cycles = 3, exec = function(cpu) end },

  -- PLA (Pull Accumulator)
  -- PLA Implied
  [0x68] = { cycles = 4, exec = function(cpu) end },

  -- PLP (Pull Processor Status)
  -- PLP Implied
  [0x28] = { cycles = 4, exec = function(cpu) end },

  -- ROL (Rotate Left)
  -- ROL Accumulator
  [0x2A] = { cycles = 2, exec = function(cpu) end },
  -- ROL Zero Page
  [0x26] = { cycles = 5, exec = function(cpu) end },
  -- ROL Zero Page,X
  [0x36] = { cycles = 6, exec = function(cpu) end },
  -- ROL Absolute
  [0x2E] = { cycles = 6, exec = function(cpu) end },
  -- ROL Absolute,X
  [0x3E] = { cycles = 7, exec = function(cpu) end },

  -- ROR (Rotate Right)
  -- ROR Accumulator
  [0x6A] = { cycles = 2, exec = function(cpu) end },
  -- ROR Zero Page
  [0x66] = { cycles = 5, exec = function(cpu) end },
  -- ROR Zero Page,X
  [0x76] = { cycles = 6, exec = function(cpu) end },
  -- ROR Absolute
  [0x6E] = { cycles = 6, exec = function(cpu) end },
  -- ROR Absolute,X
  [0x7E] = { cycles = 7, exec = function(cpu) end },

  -- RTI (Return from Interrupt)
  -- RTI Implied
  [0x40] = { cycles = 6, exec = function(cpu) end },

  -- RTS (Return from Subroutine)
  -- RTS Implied
  [0x60] = { cycles = 6, exec = function(cpu) end },

  -- SBC (Subtract with Carry)
  -- SBC Immediate
  [0xE9] = { cycles = 2, exec = function(cpu) end },
  -- SBC Zero Page
  [0xE5] = { cycles = 3, exec = function(cpu) end },
  -- SBC Zero Page,X
  [0xF5] = { cycles = 4, exec = function(cpu) end },
  -- SBC Absolute
  [0xED] = { cycles = 4, exec = function(cpu) end },
  -- SBC Absolute,X
  [0xFD] = { cycles = 4, exec = function(cpu) end },
  -- SBC Absolute,Y
  [0xF9] = { cycles = 4, exec = function(cpu) end },
  -- SBC (Indirect,X)
  [0xE1] = { cycles = 6, exec = function(cpu) end },
  -- SBC (Indirect),Y
  [0xF1] = { cycles = 5, exec = function(cpu) end },

  -- Set Carry, Decimal and Interrupt flags
  -- SEC Implied
  [0x38] = { cycles = 2, exec = function(cpu) end },
  -- SED Implied
  [0xF8] = { cycles = 2, exec = function(cpu) end },
  -- SEI Implied
  [0x78] = { cycles = 2, exec = function(cpu) end },

  -- STA (Store Accumulator)
  -- STA Zero Page
  [0x85] = { cycles = 3, exec = function(cpu) end },
  -- STA Zero Page,X
  [0x95] = { cycles = 4, exec = function(cpu) end },
  -- STA Absolute
  [0x8D] = { cycles = 4, exec = function(cpu) end },
  -- STA Absolute,X
  [0x9D] = { cycles = 5, exec = function(cpu) end },
  -- STA Absolute,Y
  [0x99] = { cycles = 5, exec = function(cpu) end },
  -- STA (Indirect,X)
  [0x81] = { cycles = 6, exec = function(cpu) end },
  -- STA (Indirect),Y
  [0x91] = { cycles = 6, exec = function(cpu) end },

  -- STX (Store X Register)
  -- STX Zero Page
  [0x86] = { cycles = 3, exec = function(cpu) end },
  -- STX Zero Page,Y
  [0x96] = { cycles = 4, exec = function(cpu) end },
  -- STX Absolute
  [0x8E] = { cycles = 4, exec = function(cpu) end },

  -- STY (Store Y Register)
  -- STY Zero Page
  [0x84] = { cycles = 3, exec = function(cpu) end },
  -- STY Zero Page,X
  [0x94] = { cycles = 4, exec = function(cpu) end },
  -- STY Absolute
  [0x8C] = { cycles = 4, exec = function(cpu) end },
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
  local instruction = opcodes[opcode]
  if instruction then
    instruction.exec(self)
    self.cycles = self.cycles + instruction.cycles
  else
    error(string.format("opcode 0x%02X not implemented.", opcode))
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
