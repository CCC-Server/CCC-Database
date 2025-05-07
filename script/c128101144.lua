--볼캐닉 인페르노 타이탄
local s,id=GetID()
local SET_BLAZE_ACCELERATOR=0xb9 -- Blaze Accelerator

function s.initial_effect(c)
  c:EnableReviveLimit()
  -- Special Summon proc from Extra Deck
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetCode(EFFECT_SPSUMMON_PROC)
  e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
  e1:SetRange(LOCATION_EXTRA)
  e1:SetCondition(s.sprcon)
  e1:SetOperation(s.sprop)
  c:RegisterEffect(e1)

  -- Send 1 "Volcanic" monster from Deck to GY
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,0))
  e2:SetCategory(CATEGORY_TOGRAVE)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetProperty(EFFECT_FLAG_DELAY)
  e2:SetCountLimit(1,id)
  e2:SetTarget(s.tgtg)
  e2:SetOperation(s.tgop)
  c:RegisterEffect(e2)

  -- Destroy and Special Summon
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,1))
  e3:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
  e3:SetType(EFFECT_TYPE_QUICK_O)
  e3:SetCode(EVENT_FREE_CHAIN)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1,{id,1})
  e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
  e3:SetTarget(s.destg)
  e3:SetOperation(s.desop)
  c:RegisterEffect(e3)
end

-- Special Summon procedure
function s.sprfilter(c,tp)
  return c:IsSetCard(0x32) and c:IsMonster() and c:IsAbleToGraveAsCost()
end
function s.sprcon(e,c)
  if c==nil then return true end
  local tp=c:GetControler()
  return Duel.IsExistingMatchingCard(function(c)
    return c:IsFaceup() and c:IsSetCard(SET_BLAZE_ACCELERATOR)
  end,tp,LOCATION_ONFIELD,0,1,nil)
  and Duel.GetLocationCount(tp,LOCATION_MZONE)>-2
  and Duel.IsExistingMatchingCard(s.sprfilter,tp,LOCATION_MZONE,0,2,nil,tp)
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
  local g=Duel.SelectMatchingCard(tp,s.sprfilter,tp,LOCATION_MZONE,0,2,2,nil,tp)
  Duel.SendtoGrave(g,REASON_COST)
end

-- Effect ①: send 1 "Volcanic" monster from Deck to GY
function s.tgfilter(c)
  return c:IsSetCard(0x32) and c:IsMonster() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
  local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
  if #g>0 then
    Duel.SendtoGrave(g,REASON_EFFECT)
  end
end

-- Effect ②: destroy and special summon
function s.desfilter(c)
  return c:IsFaceup()
end
function s.spfilter(c,e,tp)
  return c:IsRace(RACE_PYRO) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.desfilter(chkc) end
  if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_MZONE,1,nil)
    and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,nil,e,tp) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
  local g=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_MZONE,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  if tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
      Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
  end
end
