--Armed Dragon Howling
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------
	-- ① 발동: 자신 "Armed Dragon" 기준 전부 파괴 (+번)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 이름이 같은 카드는 1턴에 1장만 발동 가능
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------
-- 공용: "Armed Dragon" 세트 (0x111 가정)
--------------------------------
function s.adfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x111) and c:IsType(TYPE_MONSTER)
end

--------------------------------
-- ① 타깃 지정
--------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.adfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.adfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local tc=Duel.SelectTarget(tp,s.adfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	-- 타깃이 레벨 10 이상인지 여부를 라벨에 저장 (번뎀 용)
	if tc:IsLevelAbove(10) then
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
	-- 상대 몬스터 파괴까지 미리 정보 설정 (대충 표시용)
	local atk=tc:GetAttack()
	local g=Duel.GetMatchingGroup(function(c,atk) return c:IsFaceup() and c:IsAttackBelow(atk) end,
		tp,0,LOCATION_MZONE,nil,atk)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	end
end

--------------------------------
-- ① 처리: 파괴 + 번뎀
--------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local atk=tc:GetAttack()
	-- 상대 앞면 몬스터 중 ATK가 타깃과 이하인 몬스터 전부
	local g=Duel.GetMatchingGroup(function(c,atk) return c:IsFaceup() and c:IsAttackBelow(atk) end,
		tp,0,LOCATION_MZONE,nil,atk)
	if #g==0 then return end
	local ct=Duel.Destroy(g,REASON_EFFECT)
	-- 레벨 10 이상 "Armed Dragon"을 타깃으로 했다면, 파괴한 수 × 1000 데미지
	if ct>0 and e:GetLabel()==1 then
		Duel.BreakEffect()
		Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
		Duel.RDComplete()
	end
end
