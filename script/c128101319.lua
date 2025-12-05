--BF(블랙 페더) - 버드 아머드 윙
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	--①: 싱크로 소환 성공 시 서치 & "버스터 모드" 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--②: 싱크로 소재로 보내졌을 경우 카운터 놓기
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.ctcon)
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end

-- "블랙 페더 드래곤" ID
s.bf_dragon_id=9012916
-- "버스터 모드" ID
s.buster_mode_id=80280737
-- "검은 선풍" ID
s.whirlwind_id=91351370

-- 서치 필터: BF 카드, "블랙 페더 드래곤"이 쓰여진 카드, 또는 "검은 선풍"
-- 수정됨: aux.IsCodeListed -> c:ListsCode
function s.thfilter(c)
	return (c:IsSetCard(0x33) or c:ListsCode(s.bf_dragon_id) or c:IsCode(s.whirlwind_id))
		and c:IsAbleToHand()
end

function s.setfilter(c)
	return c:IsCode(s.buster_mode_id) and c:IsSSetable()
end

-- "블랙 페더 드래곤"이 필드/묘지에 있는지 확인
function s.bwdcheck(tp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,s.bf_dragon_id),tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		
		-- 추가 효과: 블페드 존재 시 "버스터 모드" 세트
		if s.bwdcheck(tp) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
			Duel.SSet(tp,sg)
		end
	end
end

-- ②번 효과 조건
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return c:IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO 
		and rc and (rc:IsCode(s.bf_dragon_id) or (rc:IsSetCard(0x33) and rc:IsType(TYPE_SYNCHRO)))
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetReasonCard():IsCanAddCounter(0x10,2) end
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,e:GetHandler():GetReasonCard(),2,0,0)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	if rc and rc:IsFaceup() and rc:IsLocation(LOCATION_MZONE) then
		rc:AddCounter(0x10,2)
	end
end