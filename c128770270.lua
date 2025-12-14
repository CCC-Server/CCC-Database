--Spellcraft Witch (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 패의 이 카드의 레벨은 필드의 마력 카운터 수만큼 낮아진다
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_HAND)
	e1:SetValue(s.lvval)
	c:RegisterEffect(e1)

	--② 패의 이 카드가 레벨 4 이하일 경우 특수 소환 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	c:RegisterEffect(e2)

	--③ 일반 / 특수 소환 성공 시 덱에서 스펠크래프트 몬스터 1장을 묘지로 보낸다
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

---------------------------------------------------------------
--① 레벨 계산 (필드의 마력 카운터 수만큼 레벨 하락)
function s.lvval(e,c)
	local tp=c:GetControler()
	local base=c:GetLevel()
	local ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1)
	if ct>0 then
		local newlv=math.max(1,base-ct)
		return newlv
	else
		return base
	end
end

---------------------------------------------------------------
--② 특수 소환 조건: 패의 이 카드의 레벨이 4 이하일 경우
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local lv=s.lvval(e,c)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and lv<=4
end

---------------------------------------------------------------
--③ 소환 성공 시 덱에서 "스펠크래프트" 몬스터 1장 묘지로 보내기
function s.tgfilter(c)
	return c:IsSetCard(0x761) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
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
