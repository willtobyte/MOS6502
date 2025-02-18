---@diagnostic disable: undefined-global, undefined-field, lowercase-global
local MOS6502 = require("MOS6502")

local cpu = MOS6502.new()

local fontfactory
local overlay

local labels = {}

local buffer = ""
local io = {
  [0xD010] = function(value)
    buffer = buffer .. string.char(value)
  end
}

local properties = {
  { prefix = "Output: ",               getter = function() return buffer end,               y = 10 },
  { prefix = "Cycles: ",               getter = function() return cpu.cycles end,           y = 30 },
  { prefix = "Accumulator (A): ",      getter = function() return cpu.A end,                y = 60 },
  { prefix = "X Register: ",           getter = function() return cpu.X end,                y = 80 },
  { prefix = "Y Register: ",           getter = function() return cpu.Y end,                y = 100 },
  { prefix = "Stack Pointer (SP): ",   getter = function() return cpu.SP end,               y = 120 },
  { prefix = "Program Counter (PC): ", getter = function() return cpu.PC end,               y = 140 },
  { prefix = "Processor Status (P): ", getter = function() return cpu.P end,                y = 160 },
  { prefix = "Halted: ",               getter = function() return tostring(cpu.halted) end, y = 180 },
}

cpu.write = function(self, addr, value)
  self.memory[addr] = value & 0xFF
  if io[addr] then
    io[addr](value)
  end
end

local program = {
  0xA9, 0x48,       -- LDA #$48: Load the value 0x48 ('H') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x65,       -- LDA #$65: Load the value 0x65 ('e') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x6C,       -- LDA #$6C: Load the value 0x6C ('l') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x6C,       -- LDA #$6C: Load the value 0x6C ('l') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x6F,       -- LDA #$6F: Load the value 0x6F ('o') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x20,       -- LDA #$20: Load the value 0x20 (space) into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x66,       -- LDA #$66: Load the value 0x66 ('f') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x72,       -- LDA #$72: Load the value 0x72 ('r') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x6F,       -- LDA #$6F: Load the value 0x6F ('o') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x6D,       -- LDA #$6D: Load the value 0x6D ('m') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x20,       -- LDA #$20: Load the value 0x20 (space) into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x36,       -- LDA #$36: Load the value 0x36 ('6') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x35,       -- LDA #$35: Load the value 0x35 ('5') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x30,       -- LDA #$30: Load the value 0x30 ('0') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x32,       -- LDA #$32: Load the value 0x32 ('2') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0xA9, 0x21,       -- LDA #$21: Load the value 0x21 ('!') into the accumulator
  0x8D, 0x10, 0xD0, -- STA $D010: Store the accumulator at memory address $D010
  0x02              -- KIL: Halt the processor
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
  local font = fontfactory:get("fixedsys")

  for i, prop in ipairs(properties) do
    local label = overlay:create(WidgetType.label)
    label.font = font
    label:set(prop.prefix .. "0", 10, prop.y)
    labels[i] = { widget = label, prefix = prop.prefix, getter = prop.getter, y = prop.y }
  end

  cpu:reset()
end

function loop()
  if not cpu.halted then
    cpu:step()
  end

  for i = 1, #labels do
    local l = labels[i]
    l.widget:set(l.prefix .. l.getter(), 10, l.y)
  end
end

function run()
  engine:run()
end
