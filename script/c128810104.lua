--드래고니아-마룡 바실리스크
--드래고니아-마룡 바실리스크
local s,id=GetID()
function s.initial_effect(c)
	-------------------------
	-- ① 묘지로 보내졌을 때: 드래고니아 카드 덤핑
	-------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,id)  -- 이 카드명의 효과는 1턴에 1번
	e1:SetCost(s.cost)	  -- 발동 턴 엑스트라 덱 소환 제한
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
end

s.listed_names={id} -- 자기 자신
s.listed_series={0xc05} -- "드래고니아" 시리즈

-------------------------------------
-- 공통 코스트 : 발동 턴 엑스트라 덱 소환 제한
-------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 발동 후, 드래곤족 싱크로만 엑덱에서 소환 가능
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1)) -- strings.conf에 설명문 권장
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and (not (c:IsRace(RACE_DRAGON) and c:IsType(TYPE_SYNCHRO)))
end

-------------------------------------
-- ① 덱에서 드래고니아 카드 묘지로
-------------------------------------
function s.tgfilter(c)
	return c:IsSetCard(0xc05) and not c:IsCode(id) and c:IsAbleToGrave()
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
