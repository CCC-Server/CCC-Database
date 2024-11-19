--M.A Card
local s, id = GetID()
function s.initial_effect(c)
  --①: Add "M.A" monster from deck to hand (Cannot be negated)
  local e1 = Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id, 0))
  e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND + LOCATION_MZONE)
  e1:SetCountLimit(1, id)
  e1:SetCost(s.thcost)
  e1:SetTarget(s.thtg)
  e1:SetOperation(s.thop)
  e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
  c:RegisterEffect(e1)

  --②: Gain effect when removed from play
  local e2 = Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
  e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
  e2:SetCode(EVENT_REMOVE)
  e2:SetCountLimit(1, {id, 1})
  e2:SetTarget(s.eftg)
  e2:SetOperation(s.efop)
  c:RegisterEffect(e2)
end

-- Cost function for sending this card to the Graveyard
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
  if chk == 0 then return e:GetHandler():IsAbleToGraveAsCost() end
  Duel.SendtoGrave(e:GetHandler(), REASON_COST)
end

-- Target function for adding "M.A" monster to hand
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
  if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
  Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

-- Operation function for adding "M.A" monster to hand
function s.thop(e, tp, eg, ep, ev, re, r, rp)
  Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
  local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
  if #g > 0 then
	Duel.SendtoHand(g, nil, REASON_EFFECT)
	Duel.ConfirmCards(1 - tp, g)
  end
end

-- Filter function for "M.A" monsters
function s.thfilter(c)
  return c:IsSetCard(0x30d) and c:IsAbleToHand() and c:IsType(TYPE_MONSTER) 
end

-- Filter function for "M.A" Fusion monsters
function s.thfilter2(c)
  return c:IsSetCard(0x30d) and c:IsType(TYPE_MONSTER) and c:IsType(TYPE_FUSION)
end

-- Target function for gaining protection effect
function s.eftg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
  if chkc then return chkc:IsFaceup() and chkc:IsControler(tp) and chkc:IsSetCard(0x30d) and chkc:IsType(TYPE_FUSION) end
  if chk == 0 then return Duel.IsExistingTarget(aux.FaceupFilter(s.thfilter2), tp, LOCATION_MZONE, 0, 1, nil) end
  Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
  local g = Duel.SelectTarget(tp, aux.FaceupFilter(s.thfilter2), tp, LOCATION_MZONE, 0, 1, 1, nil)
  Duel.SetOperationInfo(0, CATEGORY_ATKCHANGE, g, 1, 0, 0)
end

-- Operation function for gaining protection effect
function s.efop(e, tp, eg, ep, ev, re, r, rp)
  local tc = Duel.GetFirstTarget()
  if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
	-- Create an effect that protects other "M.A." monsters
	local e1 = Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetLabelObject(tc)
	e1:SetTarget(s.protectfilter)
	e1:SetValue(aux.tgoval)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD)
	Duel.RegisterEffect(e1, tp)
  end
end

-- Filter function to protect other "M.A." monsters
function s.protectfilter(e, c)
 return c:IsSetCard(0x30d) and  c ~= e:GetLabelObject()
end

