---@diagnostic disable: undefined-global, undefined-field, lowercase-global
local MOS6502 = require("MOS6502")

local cpu = MOS6502.new()

local fontfactory
local overlay
local label

local buffer = ""
local io = {
  [0xD010] = function(value)
    buffer = buffer .. string.char(value)
  end
}

cpu.write = function(self, addr, value)
  self.memory[addr] = value & 0xFF
  if io[addr] then
    io[addr](value)
  end
end

local program = {
  0xA9, 0x48,       -- LDA #$48: 'H'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x65,       -- LDA #$65: 'e'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x6C,       -- LDA #$6C: 'l'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x6C,       -- LDA #$6C: 'l'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x6F,       -- LDA #$6F: 'o'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x20,       -- LDA #$20: ' '
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x66,       -- LDA #$66: 'f'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x72,       -- LDA #$72: 'r'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x6F,       -- LDA #$6F: 'o'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x6D,       -- LDA #$6D: 'm'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x20,       -- LDA #$20: ' '
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x36,       -- LDA #$36: '6'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x35,       -- LDA #$35: '5'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x30,       -- LDA #$30: '0'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x32,       -- LDA #$32: '2'
  0x8D, 0x10, 0xD0, -- STA $D010
  0xA9, 0x21,       -- LDA #$21: '!'
  0x8D, 0x10, 0xD0, -- STA $D010
  0x02              -- KIL: Halt
}

local address = 0x8000
for i, byte in ipairs(program) do
  cpu.memory[address + i - 1] = byte
end

cpu.memory[0xFFFC] = address & 0xFF
cpu.memory[0xFFFD] = (address >> 8) & 0xFF

function setup()
  _G.engine = EngineFactory.new()
      :with_title("MOS6502")
      :with_width(1920)
      :with_height(1080)
      :with_scale(3.0)
      :with_gravity(9.8)
      :with_fullscreen(false)
      :create()

  overlay = engine:overlay()

  fontfactory = engine:fontfactory()

  label = overlay:create(WidgetType.label)
  label.font = fontfactory:get("fixedsys")
  label:set("", 10, 10)
end

function loop()
  cpu:reset()

  while not cpu.halted do
    cpu:step()
  end

  label:set(buffer)
end

function run()
  engine:run()
end
